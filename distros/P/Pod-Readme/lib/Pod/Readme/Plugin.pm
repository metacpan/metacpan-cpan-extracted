package Pod::Readme::Plugin;

use v5.10.1;

use Moo::Role;

our $VERSION = 'v1.2.1';

use Class::Method::Modifiers qw/ fresh /;
use Hash::Util qw/ lock_keys /;
use Try::Tiny;

use Pod::Readme::Types qw/ Indentation /;

=head1 NAME

Pod::Readme::Plugin - Plugin role for Pod::Readme

=head1 DESCRIPTION

L<Pod::Readme> v1.0 and later supports plugins that extend the
capabilities of the module.

=head1 WRITING PLUGINS

Writing plugins is straightforward. Plugins are L<Moo::Role> modules
in the C<Pod::Readme::Plugin> namespace.  For example,

  package Pod::Readme::Plugin::myplugin;

  use Moo::Role;

  sub cmd_myplugin {
      my ($self, @args) = @_;
      my $res = $self->parse_cmd_args( [qw/ arg1 arg2 /], @args );

      ...
  }

When L<Pod::Readme> encounters POD with

  =for readme plugin myplugin arg1 arg2

the plugin role will be loaded, and the C<cmd_myplugin> method will be
run.

Note that you do not need to specify a C<cmd_myplugin> method.

Any method prefixed with "cmd_" will be a command that can be called
using the C<=for readme command> syntax.

A plugin parses arguments using the L</parse_cmd_arguments> method and
writes output using the write methods noted above.

See some of the included plugins, such as
L<Pod::Readme::Plugin::version> for examples.

Any attributes in the plugin should be prefixed with the name of the
plugin, to avoid any conflicts with attribute and method names from
other plugins, e.g.

  use Types::Standard qw/ Int /;

  has 'myplugin_heading_level' => (
    is      => 'rw',
    isa     => Int,
    default => 1,
    lazy    => 1,
  );

Attributes should be lazy to ensure that their defaults are properly
set.

Be aware that changing default values of an attribute based on
arguments means that the next time a plugin method is run, the
defaults will be changed.

Custom types in L<Pod::Readme::Types> may be useful for attributes
when writing plugins, e.g.

  use Pod::Readme::Types qw/ File HeadingLevel /;

  has 'myplugin_file' => (
    is      => 'rw',
    isa     => File,
    coerce  => sub { File->coerce(@_) },
    default => 'Changes',
    lazy => 1,
  );

  # We add this file to the list of dependencies

  around 'depends_on' => sub {
    my ($orig, $self) = @_;
    return ($self->myplugin_file, $self->$orig);
  };

=head1 ATTRIBUTES

=head2 C<verbatim_indent>

The number of columns to indent a verbatim paragraph.

=cut

has verbatim_indent => (
    is      => 'ro',
    isa     => Indentation,
    default => 2,
);

=head1 METHODS

=cut

sub _parse_arguments {
    my ( $self, $line ) = @_;
    my @args = ();

    my $i = 0;
    my $prev;
    my $in_quote = '';
    my $arg_buff = '';
    while ( $i < length($line) ) {

        my $curr = substr( $line, $i, 1 );
        if ( $curr !~ m/\s/ || $in_quote ) {
            $arg_buff .= $curr;
            if ( $curr =~ /["']/ && $prev ne "\\" ) {
                $in_quote = ( $curr eq $in_quote ) ? '' : $curr;
            }
        }
        elsif ( $arg_buff ne '' ) {
            push @args, $arg_buff;
            $arg_buff = '';
        }
        $prev = $curr;
        $i++;
    }

    if ( $arg_buff ne '' ) {
        push @args, $arg_buff;
    }

    return @args;
}

=head2 C<parse_cmd_args>

  my $hash_ref = $self->parse_cmd_args( \@allowed_keys, @args);

This command parses arguments for a plugin and returns a hash
reference containing the argument values.

The C<@args> parameter is a list of arguments passed to the command
method by L<Pod::Readme::Filter>.

If an argument contains an equals sign, then it is assumed to take a
string.  (Strings containing whitespace should be surrounded by
quotes.)

Otherwise, an argument is assumed to be boolean, which defaults to
true. If the argument is prefixed by "no-" or "no_" then it is given a
false value.

If the C<@allowed_keys> parameter is given, then it will reject
argument keys that are not in that list.

For example,

  my $res = $self->parse_cmd_args(
              undef,
              'arg1',
              'no-arg2',
              'arg3="This is a string"',
              'arg4=value',
  );

will return a hash reference containing

  {
     arg1 => 1,
     arg2 => 0,
     arg3 => 'This is a string',
     arg4 => 'value',
  }

=cut

sub parse_cmd_args {
    my ( $self, $allowed, @args ) = @_;

    my ( $key, $val, %res );
    while ( my $arg = shift @args ) {

        state $eq = qr/=/;

        if ( $arg =~ $eq ) {
            ( $key, $val ) = split $eq, $arg;

            # TODO - better way to remove surrounding quotes
            if ( ( $val =~ /^(['"])(.*)(['"])$/ ) && ( $1 eq $3 ) ) {
                $val = $2 // '';
            }

        }
        else {
            $val = 1;
            if ( ($key) = ( $arg =~ /^no[_-](\w+(?:[-_]\w+)*)$/ ) ) {
                $val = 0;
            }
            else {
                $key = $arg;
            }
        }

        $res{$key} = $val;
    }

    if ($allowed) {
        try {
            lock_keys( %res, @{$allowed} );
        }
        catch {
            if (/Hash has key '(.+)' which is not in the new key set/) {
                die sprintf( "Invalid argument key '\%s'\n", $1 );
            }
            else {
                die "Unknown error checking argument keys\n";
            }
        };
    }

    return \%res;
}

=head2 C<write_verbatim>

  $self->write_verbatim($text);

A utility method to write verbatim text, indented by
L</verbatim_indent>.

=cut

sub write_verbatim {
    my ( $self, $text ) = @_;

    my $indent = ' ' x ( $self->verbatim_indent );
    $text =~ s/^/${indent}/mg;
    $text =~ s/([^\n])\n?$/$1\n\n/;

    $self->write($text);
}

=begin :internal

=head2 C<_write_cmd>

  $self->_write_cmd('=head1 SECTION');

An internal utility method to write a command line.

=end :internal

=cut

sub _write_cmd {
    my ( $self, $text ) = @_;
    $text =~ s/([^\n])\n?$/$1\n\n/;

    $self->write($text);
}

=head2 C<write_para>

  $self->write_para('This is a paragraph');

Utility method to write a POD paragraph.

=cut

sub write_para {
    my ( $self, $text ) = @_;
    $text //= '';
    $self->write( $text . "\n\n" );
}

=head2 C<write_head1>

=head2 C<write_head2>

=head2 C<write_head3>

=head2 C<write_head4>

=head2 C<write_over>

=head2 C<write_item>

=head2 C<write_back>

=head2 C<write_begin>

=head2 C<write_end>

=head2 C<write_for>

=head2 C<write_encoding>

=head2 C<write_cut>

=head2 C<write_pod>

  $self->write_head1($text);

Utility methods to write POD specific commands to the C<output_file>.

These methods ensure the POD commands have extra newlines for
compatibility with older POD parsers.

=cut

{
    foreach my $cmd (
        qw/ head1 head2 head3 head4
        over item begin end for encoding /
      )
    {
        fresh(
            "write_${cmd}" => sub {
                my ( $self, $text ) = @_;
                $text //= '';
                $self->_write_cmd( '=' . $cmd . ' ' . $text );
            }
        );
    }

    foreach my $cmd (qw/ pod back cut  /) {
        fresh(
            "write_${cmd}" => sub {
                my ($self) = @_;
                $self->_write_cmd( '=' . $cmd );
            }
        );
    }

}

use namespace::autoclean;

1;
