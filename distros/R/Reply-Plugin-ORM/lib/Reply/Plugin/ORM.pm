package Reply::Plugin::ORM;
use 5.008005;
use strict;
use warnings;
use parent qw/ Reply::Plugin /;

use Module::Load;
use Path::Tiny;

our $VERSION = "0.01";
my $ORM;

sub new {
    my ($class, %opts) = @_;

    my $db_name = $ENV{PERL_REPLY_PLUGIN_ORM};
    return $class->SUPER::new(%opts) unless defined $db_name;
    
    my $config_path = delete $opts{config}
        or Carp::croak "[Error] Please set config file's path at .replyrc";
    my $config = $class->_config($db_name, $config_path);
    $class->_config_validate($config);

    my $orm_module = "Reply::Plugin::ORM::$config->{orm}";  
    eval "require $orm_module";
    Carp::croak "[Error] Module '$orm_module' not found." if $@;

    load $orm_module;
    $ORM = $orm_module->new($db_name => $config, %opts);
    my @methods = (@{$ORM->{methods}}, qw/ Show_dbname Show_methods /);

    no strict 'refs';
    for my $method (@{$ORM->{methods}}) {
        *{"main::$method"} = sub { _command(lc $method, @_ ) };
    }
    *main::Show_dbname  = sub { return $db_name };
    *main::Show_methods = sub { return @methods };
    use strict 'refs';

    printf "Connect database : %s (using %s)\n", $db_name, $config->{orm};

    return $class->SUPER::new(%opts, methods => \@methods);
}    

sub tab_handler {
    my $self = shift;
    my ($line) = @_;

    return if length $line <= 0; 
    return if $line =~ /^#/; # command
    return if $line =~ /->\s*$/; # method call
    return if $line =~ /[\$\@\%\&\*]\s*$/;

    return sort grep {
        index ($_, $line) == 0
    } @{$self->{methods}};
}

sub _config {
    my ($class, $db_name, $config_path) = @_;

    my $config_fullpath = path($config_path);
    Carp::croak "[Error] Config file not found: $config_fullpath" unless -f $config_fullpath;
    my $config = do $config_fullpath 
        or Carp::croak "[Error] Failed to load config file: $config_path";

    Carp::croak "[Error] Setting of '$db_name' not found at config file" unless $config->{$db_name};
    return $config->{$db_name}
}

sub _config_validate {
    my ($class, $config) = @_;
    Carp::croak "[Error] Please set 'orm' at config file." unless $config->{orm};
    Carp::croak "[Error] Please set 'connect_info' at config file." unless $config->{connect_info};
}

sub _command {
    my $command = shift || '';
    return $ORM->{orm}->$command(@_);
}

1;
__END__

=encoding utf-8

=head1 NAME

Reply::Plugin::ORM - Reply + O/R Mapper

=head1 SYNOPSIS

    ; .replyrc
    ...
    [ORM]
    config = ~/.reply-plugin-orm
    otogiri_plugins = DeleteCascade      ; You can use O/R Mapper plugin (in this case, 'Otogiri::Plugin::DeleteCascade'). 
    teng_plugins    = Count,SearchJoined ; You can use multiple plugins, like this.

    ; .reply-plugin-orm
    +{
        sandbox => {
            orm          => 'Otogiri', # or 'Teng'
            connect_info => ["dbi:SQLite:dbname=...", '', '', { ... }],
        }
    }
    
    $ PERL_REPLY_PLUGIN_ORM=sandbox reply

=head1 DESCRIPTION

Reply::Plugin::ORM is Reply's plugin for operation of database using O/R Mapper.
In this version, we have support for Otogiri and Teng.

=head1 METHODS

Using this module, you can use O/R Mapper's method at Reply shell.
If you set loading of O/R Mapper's plugin in config file, you can use method that provided by plugin on shell.

In order to prevent the redefined of function, these method's initials are upper case. 
You can call Teng's C<single> method, like this: 
    
    1> Single 'table_name';

In addition, this module provides two additional methods.

=over 4

=item * C<Show_methods>

This method outputs a list of methods provided by this module.

=item * C<Show_dbname>

This method outputs the name of database which you are connecting.

=back

=head1 LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

papix E<lt>mail@papix.netE<gt>

=head1 SEE ALSO

L<Reply>

L<Otogiri>

L<Teng>

=cut

