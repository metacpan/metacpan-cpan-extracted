package Smart::Options;
use strict;
use warnings;
use 5.010001;
our $VERSION = '0.06';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(argv);

use List::MoreUtils qw(uniq);
use Text::Table;
use File::Slurp;

sub new {
    my $pkg = shift;
    my %opt = @_;

    my $self = bless {
        alias    => {},
        default  => {},
        boolean  => {},
        demand   => {},
        usage    => "Usage: $0",
        describe => {},
        type     => {},
        subcmd   => {},
        coerce   => {},
        env      => {},
        env_prefix => '',
    }, $pkg;

    if ($opt{add_help} // 1) {
        $self->options(h => {
                alias => 'help',
                describe => 'show help',
            });
        $self->{add_help} = 1;
    }

    $self;
}

sub argv {
    Smart::Options->new->parse(@_);
}

sub _set {
    my $self = shift;
    my $param = shift;

    my %args = @_;
    for my $option (keys %args) {
        $self->{$param}->{$option} = $args{$option};
    }

    $self;
}

sub alias { shift->_set('alias', @_) }
sub default { shift->_set('default', @_) }
sub describe { shift->_set('describe', @_) }
sub type { shift->_set('type', @_) }
sub subcmd { shift->_set('subcmd', @_) }

sub _set_flag {
    my $self = shift;
    my $param = shift;

    for my $option (@_) {
        $self->{$param}->{$option} = 1;
    }

    $self;
}

sub boolean { shift->_set_flag('boolean', @_) }
sub demand { shift->_set_flag('demand', @_) }
sub env { shift->_set_flag('env', @_) }

sub options {
    my $self = shift;

    my %args = @_;
    while (my($opt, $setting) = each %args) {
        for my $key (keys %$setting) {
            $self->$key($opt, $setting->{$key});
        }
    }

    $self;
}

sub coerce {
    my ($self, $isa, $type, $generater) = @_;

    $self->{coerce}->{$isa} = {
        type => $type,
        generater => $generater,
    };
}

sub usage { $_[0]->{usage} = $_[1]; $_[0] }
sub env_prefix { $_[0]->{env_prefix} = $_[1]; $_[0] }

sub _get_opt_desc {
    my ($self, $option) = @_;

    my @opts = ($option);
    while ( my($opt, $val) = each %{$self->{alias}} ) {
        push @opts, $opt if $val eq $option;
    }

    return join(', ', map { (length($_) == 1 ? '-' : '--') . $_ } sort @opts);
}

sub _get_describe {
    my ($self, $option) = @_;

    my $desc = $self->{describe}->{$option};
    while ( my($opt, $val) = each %{$self->{alias}} ) {
        $desc ||= $self->{describe}->{$opt} if $val eq $option;
    }

    return $desc ? ucfirst($desc) : '';
}

sub _get_default {
    my ($self, $option) = @_;

    my $value = $self->{default}->{$option};
    while ( my($opt, $val) = each %{$self->{alias}} ) {
        $value ||= $self->{default}->{$opt} if $val eq $option;
    }

    $value;
}

sub help {
    my $self = shift;

    my $alias = $self->{alias};
    my $demand = $self->{demand};
    my $describe = $self->{describe};
    my $default = $self->{default};
    my $boolean = $self->{boolean};
    my $help = $self->{usage} . "\n";

    if (scalar(keys %$demand) or scalar(keys %$describe)) {
        my @opts;
        for my $opt (uniq sort keys %$demand, keys %$describe, keys %$default, keys %$boolean, values %$alias) {
            next if $alias->{$opt};
            push @opts, [
                $self->_get_opt_desc($opt),
                $self->_get_describe($opt),
                $boolean->{$opt} ? '[boolean]' : '',
                $demand->{$opt} ? '[required]' : '',
                $self->_get_default($opt) ? "[default: @{[$self->_get_default($opt)]}]" : '',
            ];
        }

        my $sep = \'  ';
        $help .= "\nOptions:\n";
        $help .= Text::Table->new( $sep, '', $sep, '', $sep, '', $sep, '', $sep, '' )
                            ->load(@opts)->stringify . "\n";
        if (keys %{$self->{subcmd}}) {
            $help .= "Implemented commands are:\n";
            $help .= "  " . join(', ', sort keys %{$self->{subcmd}}) . "\n\n";
        }
    }

    $help;
}

sub showHelp {
    my ($self, $fh) = @_;
    $fh //= *STDERR;

    print $fh $self->help;

}

sub _set_v2a {
    my ($argv, $key, $value, $k) = @_;

    if ($k) {
        $argv->{$key} //= {};
        _set_v2a($argv->{$key}, $k, $value);
    }
    elsif (exists $argv->{$key}) {
        if (ref($argv->{$key})) {
            push @{$argv->{$key}}, $value;
        }
        else {
            $argv->{$key} = [ $argv->{$key}, $value ];
        }
    }
    else {
        $argv->{$key} = $value;
    }
}

sub _get_real_name {
    my ($self, $opt) = @_;

    while (my $name = $self->{alias}->{$opt}) {
        $opt = $name;
    }
    return $opt;
}

sub _load_config {
    my ($self, $argv, $file) = @_;

    for my $line (read_file($file)) {
        next if $line =~ /^\[/; # section
        next if $line =~ /^;/;  # comment
        next if $line !~ /=/;   # bad format;

        chomp($line);
        if ($line =~ /^(.+?[^\\])=(.*)$/) {
            $argv->{$1} = $2;
        }
    }
}

sub parse {
    my $self = shift;
    push @_, @ARGV unless @_;

    my $argv = {};
    my @args;
    my $boolean = $self->{boolean};

    my $key;
    my $nest_key;
    my $stop = 0;
    for my $arg (@_) {
        if ($stop) {
            push @args, $arg;
            next;
        }
        if ($arg =~ /^--((?:\w|-|\.)+)=(.+)$/) {
            my ($opt, $k) = split(/\./, $1);
            my $option = $self->_get_real_name($opt);
            if ($k) {
                _set_v2a($argv, $option, $2, $k);
            } else {
                _set_v2a($argv, $option, $2);
            }
        }
        elsif ($arg =~ /^(-(\w)|--((?:\w|-|\.)+))$/) {
            if ($key) {
                $argv->{$key} = 1;
            }
            my $opt = $2 // $3;
            if ($opt =~ /^no\-(.+)$/) {
                my $option = $self->_get_real_name($1);
                $argv->{$option} = 0;
                next;
            }
            ($opt, my $k) = split(/\./, $opt);
            my $option = $self->_get_real_name($opt);
            if ($boolean->{$option}) {
                if ($k) {
                    $argv->{$option} //= {};
                    $argv->{$option}->{$k} = 1;
                } else {
                    $argv->{$option} = 1;
                }
            }
            else {
                $key = $option;
                $nest_key = $k;
            }
        }
        elsif ($arg =~ /^-(\w(?:\w|-|\.)+)$/) {
            if ($key) {
                $argv->{$key} = 1;
            }
            my $opt_str = $1;
            if ($opt_str =~ /^(.)([0-9])+$/) {
                my $option = $self->_get_real_name($1);
                $argv->{$option} = $2;
            } else {
                for (split //, $opt_str) {
                    my $option = $self->_get_real_name($_);
                    $argv->{$option} = 1;
                }
            }
        }
        elsif ($arg =~ /^--$/) {
            # stop parsing
            $stop = 1;
            next;
        }
        else {
            if ($key) {
                if ($nest_key) {
                    _set_v2a($argv, $key, $arg, $nest_key);
                } else {
                    _set_v2a($argv, $key, $arg);
                }
                # reset
                $key = $nest_key = undef;
            }
            else {
                if (!scalar(@args) && keys %{$self->{subcmd}}) {
                    if ( $self->{subcmd}->{$arg} ) {
                        $argv->{command} = $arg;
                        $stop = 1;
                        next;
                    }
                    else {
                        die "sub command '$arg' not defined.";
                    }
                }

                push @args, $arg;
            }
        }
    }
    if ($key) {
        if ($nest_key) {
            $argv->{$key} //= {};
            $argv->{$key}->{$nest_key} = 1;
        } else {
            $argv->{$key} = 1;
        }
    }

    if (my $parser = $self->{subcmd}->{$argv->{command}||''}) {
        $argv->{cmd_option} = $parser->parse(@args);
    } else {
        $argv->{_} = \@args;
    }

    for my $env (keys %{$self->{env}}) {
        if (defined($ENV{uc($self->{env_prefix}."_$env")})) {
            my $option = $self->_get_real_name($env);
            $argv->{$option} //= $ENV{uc($self->{env_prefix}."_$env")};
        }
    }

    while (my ($key, $val) = each %{$self->{default}}) {
        my $opt = $self->_get_real_name($key);
        if (ref($val) && ref($val) eq 'CODE') {
            $argv->{$opt} //= $val->();
        }
        else {
            $argv->{$opt} //= $val;
        }
    }

    while (my ($key, $val) = each %{$self->{type}}) {
        next if $val ne 'Config';
        next if !($argv->{$key}) || !(-f $argv->{$key});
        $self->_load_config($argv, delete $argv->{$key});
    }

    for my $key (keys %{$self->{demand}}) {
        my $opt = $self->_get_real_name($key);
        if (!$argv->{$opt}) {
            $self->showHelp;
            print STDERR "\nMissing required arguments: $opt\n";
            die;
        }
    }

    for my $key (keys %{$self->{type}}) {
        my $opt = $self->_get_real_name($key);
        my $type = $self->{type}->{$key};
        if (my $c = $self->{coerce}->{$type}) {
            $type = $c->{type};
            $argv->{$opt} = $c->{generater}->($argv->{$opt});
        }
        my $check = 0;
        if ($type eq 'Bool') {
            $argv->{$opt} //= 0;
            $check = ($argv->{$opt} =~ /^(0|1)$/) ? 1 : 0;
        } elsif ($type eq 'Str') {
            $check = 1;
        } elsif ($type eq 'Int') {
            if ($argv->{$opt}) {
                $check = ($argv->{$opt} =~ /^\-?\d+$/) ? 1 : 0;
            } else {
                $check = 1;
            }
        } elsif ($type eq 'Num') {
            if ($argv->{$opt}) {
                $check = ($argv->{$opt} =~ /^\-?\d+(\.\d+)$/) ? 1 : 0;
            } else {
                $check = 1;
            }
        } elsif ($type eq 'ArrayRef') {
            $argv->{$opt} //= [];
            unless (ref($argv->{$opt})) {
                $argv->{$opt} = [$argv->{$opt}];
            }
            $check = (ref($argv->{$opt}) eq 'ARRAY') ? 1 : 0;
        } elsif ($type eq 'HashRef') {
            $argv->{$opt} //= {};
            $check = (ref($argv->{$opt}) eq 'HASH') ? 1 : 0;
        } elsif ('Config') {
            if ($argv->{$opt} && !(-f $argv->{$opt})) {
                die "cannot load config file '@{[$argv->{$opt}]}\n";
            }
            $check = 1;
        } else {
            die "cannot find type constraint '$type'\n";
        }
        unless ($check) {
            die "Value '@{[$argv->{$opt}]}' invalid for option $opt($type)\n";
        }
    }

    if ($argv->{help} && $self->{add_help}) {
        $self->showHelp;
        die;
    }

    $argv;
}


1;
__END__

=encoding utf8

=head1 NAME

Smart::Options - smart command line options processor

=head1 SYNOPSIS

  use Smart::Options;

  my $argv = Smart::Options->new->argv;

  if ($argv->{rif} - 5 * $argv->{xup} > 7.138) {
      say 'Buy more fiffiwobbles';
  }
  else {
     say 'Sell the xupptumblers';
  }

  # $ ./example.pl --rif=55 --xup=9.52
  # Buy more fiffiwobbles
  #
  # $ ./example.pl --rif 12 --xup 8.1
  # Sell the xupptumblers

=head1 DESCRIPTION

Smart::Options is a library for option parsing for people tired option parsing.
This module is analyzed as people interpret an option intuitively.

=head1 METHOD

=head2 new()

Create a parser object.

  use Smart::Options;

  my $argv = Smart::Options->new->parse(qw(-x 10 -y 2));

=head2 parse(@args)

parse @args. return hashref of option values.
if @args is empty Smart::Options use @ARGV

=head2 argv(@args)

shortcut method. this method auto export.

  use Smart::Options;
  say argv(qw(-x 10))->{x};

is the same as

  use Smart::Options ();
  Smart::Options->new->parse(qw(-x 10))->{x};

=head2 alias($alias, $option)

set alias for option. you can use "$option" field of argv.

  use Smart::Options;
  
  my $argv = Smart::Options->new->alias(f => 'file')->parse(qw(-f /etc/hosts));
  $argv->{file} # => '/etc/hosts'

=head2 default($option, $default_value)

set default value for option.

  use Smart::Options;
  
  my $argv = Smart::Options->new->default(y => 5)->parse(qw(-x 10));
  $argv->{x} + $argv->{y} # => 15

=head2 describe($option, $msg)

set option help message.

  use Smart::Options;
  my $opt = Smart::Options->new()->alias(f => 'file')->describe('Load a file');
  say $opt->help;

  # Usage: ./example.pl
  #
  # Options:
  #    -f, --file  Load a file
  #

=head2 boolean($option, $option2, ...)

interpret 'option' as a boolean.

  use Smart::Options;
  
  my $argv = Smart::Options->new->parse(qw(-x 11 -y 10));
  $argv->{x} # => 11
  
  my $argv2 = Smart::Options->new->boolean('x')->parse(qw(-x 11 -y 10));
  $argv2->{x} # => true (1)

=head2 demand($option, $option2, ...)

show usage (showHelp()) and exit if $option wasn't specified in args.

  use Smart::Options;
  my $opt = Smart::Options->new()->alias(f => 'file')
                                 ->demand('file')
                                 ->describe('Load a file');
  $opt->argv(); # => exit

  # Usage: ./example.pl
  #
  # Options:
  #    -f, --file  Load a file [required]
  #

=head2 options($key => $settings, ...)

  use Smart::Options;
  my $opt = Smart::Options->new()
    ->options( f => { alias => 'file', default => '/etc/passwd' } );

is the same as

  use Smart::Options;
  my $opt = Smart::Options->new()
              ->alias(f => 'file')
              ->default(f => '/etc/passwd');

=head2 type($option => $type)

set type check for option value

  use Smart::Options;
  my $opt = Smart::Options->new()->type(foo => 'Int');

  $opt->parse('--foo=bar') # => fail
  $opt->parse('--foo=3.14') # => fail
  $opt->parse('--foo=1') # => ok

support type is here.

  Bool
  Str
  Int
  Num
  ArrayRef
  HashRef
  Config

=head3 Config

'Config' is special type.
The contents will be read into each option if a file name is specified as a Config type option. 

  use Smart::Options;
  my $opt = Smart::Options->new()->type(conf => 'Config');
  $opt->parse(qw(--conf=.optrc));

config file format is simple. see http://en.wikipedia.org/wiki/INI_file

  ; this is comment
  [section]
  key=value
  key2=value2

=head2 coerce( $newtype => $sourcetype, $generator )

define new type and convert logic.

  use Smart::Options;
  use Path::Class; # export 'file'
  my $opt = Smart::Options->new()->coerce(File => 'Str', sub { file($_[0]) })
                                 ->type(file => 'File');
  
  $opt->parse('--foo=/etc/passwd');
  $argv->{file} # => Path::Class::File instance

=head2 usage

set a usage message to show which command to use. default is "Usage: $0".

=head2 help

return help message string

=head2 showHelp($fh)

print usage message. default output STDERR.

=head2 subcmd($cmd => $parser)

set a sub command. $parser is another Smart::Option object.

  use Smart::Options;
  my $opt = Smart::Options->new()
              ->subcmd(add => Smart::Options->new())
              ->subcmd(minus => Smart::Options->new());

=head1 DSL

see also L<Smart::Options::Declare>

=head1 PARSING TRICKS

=head2 stop parsing

use '--' to stop parsing.

  use Smart::Options;
  use Data::Dumper;

  my $argv = argv(qw(-a 1 -b 2 -- -c 3 -d 4));
  warn Dumper($argv);

  # $VAR1 = {
  #        'a' => '1',
  #        'b' => '2',
  #        '_' => [
  #                 '-c',
  #                 '3',
  #                 '-d',
  #                 '4'
  #               ]
  #      };

=head2 negate fields

'--no-key' set false to $key.

  use Smart::Options;
  argv(qw(-a --no-b))->{b}; # => 0

=head2 duplicates

If set flag multiple times it will get arrayref.

  use Smart::Options;
  argv(qw(-x 1 -x 2 -x 3))->{x}; # => [1, 2, 3]

=head2 dot notation

  use Smart::Optuions;
  argv(qw(--foo.x 1 --foo.y 2)); # => { foo => { x => 1, y => 2 } }

=head1 AUTHOR

Kan Fushihara E<lt>kan.fushihara@gmail.comE<gt>

=head1 SEE ALSO

https://www.npmjs.com/package/minimist

L<GetOpt::Casual>, L<opts>, L<GetOpt::Compat::WithCmd>

=head1 LICENSE

Copyright (C) Kan Fushihara

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
