package SQL::SqlObject::Config;

use strict;
use warnings;
require Carp;

our $VERSION = '0.01';

our %SqlConfig = 
(

    #----------------------------------------
    # DBI Connect settings
    #----------------------------------------

    # which DBD driver to use by default
    DSN           => 'dbi:Sybase',

    # prepended to database name in the DBI connect string
    NAME_PREFIX   => 'database=',

    # database to connect to, by default
    NAME          => 'cezb-html',

    # user to connect as, by default
    USER          => 'perl',

    # password for DB_USER
    PASSWORD      => '',

    # other parameters
    OTHER_ARGS    => '',

    OTHER_ARG_SEP => ';',

    #----------------------------------------
    # constructor arguments
    #   defined here, so they can be modifed
    #   by SQL::SqlObject sub-classes.
    #----------------------------------------

    # Lists each of the constructor arguments (in the
    # order to be received, when provided positionaly)
    # as hash refs.
    #
    # Key is the name of the arg, to be used to build 
    # it's accessor method
    #
    # Value is an array reference, fields are listed below
    #
    #   2)   arg name, which must have an accessor method
    #        method of the same name
    #   2)   a vertical bar seperated list of aliases
    #   3)   list ref of env vars to search for a value
    #   4)   a SqlConfig key from which to read default
    #
    ARGS => 
    [
       ['db_name','name|database','','NAME'],
       ['db_user','user','','USER'],
       ['db_password','password|pass|passwd', '','PASSWORD'],
       ['db_dsn','DSN|dsn','','DSN'],
       ['db_name_prefix','','','NAME_PREFIX'],
    ],

);

sub arg_index ($)

    #
    # given: $KEY
    #
    # returns the index of $KEY in $SqlConfig->{ARGS}
    # or barfs is $KEY is unknown in $SqlConfig->{ARGS}

{
    my $key = lc $_[-1]; $key =~ s/^-+//;
    my $args = $SqlConfig{ARGS};
    for (0..$#$args)
    {
	return $_ if $key =~ /^(?:$SqlConfig{ARGS}[$_][0]|$SqlConfig{ARGS}[$_][1])$/;
    }
    Carp::confess "Unknown parameter to SqlObject: \"$_[-1]\"\n";
}

sub add_arg ($;$$$$)

    # given: $KEY, $aliases, $env_or_envlist, $default, $before_key
    #
    # registers KEY for a parameter to the SqlObject constructor, by
    # adding to the ARGS list in %SqlConfig.  $aliases, if provided is
    # either a pipe-seperated list of other names for KEY or simply a
    # list (array ref) of other names for key. $env_or_envlist is
    # either a SCALAR constaining the name of an enviroment variable
    # to search for KEYS value, when the constructor is run, or a list
    # there of. $before_key

{
    my ($key, $ali, $env, $def, $bef) = @_;
    my @rec = $key;
    $ali = join '|', @$ali if ref $ali;
    push @rec, (defined $ali and $ali) ? $ali : '';
    push @rec, (defined $env and $env) ? $env : '';
    push @rec, (defined $def and $def) ? $def : '';
    if (defined $bef and $bef)
    {
        $bef = arg_index $bef;
    }
    else
    {
        $bef = @{$SqlConfig{ARGS}};
    }
    splice @{$SqlConfig{ARGS}}, $bef, 0, \@rec;
    return;
}

sub add_alias ($@)

    # given:  $KEY, @ALISES
    #
    # add @ALISES to $KEY in $SqlConfig{ARGS}

{
    my $key = shift;
    return unless @_;
    my $ali = $SqlConfig{ARGS}[ arg_index $key ][1];
    $ali .= '|' if $ali;
    $ali .= join '|',@_;
    $ali =~ s/|$//;
    $SqlConfig{ARGS}[ arg_index $key ][1] = $ali;
    return;
}

sub add_enviroment_variable

    # given: $KEY, @ENVS
    #
    # add @ENVS to $KEY in $SqlConfig{ARGS}

{
    my $key = shift;
    return unless @_;
    my $env = $SqlConfig{ARGS}[ arg_index $key ][2];
    $env = ($env && !ref $env) ? [$env] : (ref $env ? $env : []);
    $env = [ $env ] if $env and not ref $env;
    unshift @$env, @_;
    $SqlConfig{ARGS}[ arg_index $key ][2] = $env;
    return;
}

sub set_default ($$)

    # given: $KEY, $DEFAULT
    #
    # set the default for $KEY in $SqlConfig{ARGS}

{
    my ($key, $def) = @_;
    return unless defined $def;
    $SqlConfig{ARGS}[ arg_index $key ][2] = $def;
    return;
}

sub set ($@)

    # given:  $KEY, $value
    #
    # add $KEY to %SqlConfig

{
  my $key = shift;
  return unless (@_ and defined $_[0]) or not exists $SqlConfig{$key};
  $SqlConfig{$key} = (not defined $_[0]) ? '' : ($#_ ? \@_ : $_[0]);
  return;
}
1;

