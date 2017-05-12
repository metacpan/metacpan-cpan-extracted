package Template::Provider::DBI;

use DBI;
use DateTime::Format::DBI;
use base 'Template::Provider';

our $VERSION = '0.03';

sub _init
{
    # check dbi specific params from args, then call super
    # modified timestamps?
    # precompiled?
    my ($self, $args) = @_;

    $self->{$_} = $args->{$_} for keys %$args;

    if($self->{DBI_DBH} && $self->{DBI_DSN})
    {
        return $self->error("DBI:Can't use DBI_DBH and DBI_DSN at the same time");
    }

    if($self->{DBI_DSN})
    {
        $self->{DBI_DBH} = DBI->connect($self->{DBI_DSN}, $self->{DBI_USER}, $self->{DBI_PASSWD}) or return $self->error("DBI: Failed to connect to $self->{DBI_DSN}, $self->{DBI_USER}, $self->{DBI_PASSWD}, $DBI::errstr");
    }

    $self->{DBI_TABLE}         ||= 'templates';
    $self->{DBI_MODIFIEDFIELD} ||= 'modified';
    $self->{DBI_TMPLFIELD}     ||= 'template';
    $self->{DBI_FILEFIELD}     ||= 'filename';
    $self->{DBI_CURRENTTIME}   ||= 'current_timestamp';
#    $self->{DBI_QUERY}         ||= "SELECT $self->{DBI_TMPLFIELD} FROM $self->{DBI_TABLE} WHERE $self->{DBI_FILEFIELD} = ?";
    
    eval {
        $self->{DBI_DT}        ||= DateTime::Format::DBI->new($self->{DBI_DBH}); };
    if($@)
    {
       warn "DateTime::Format:: for $self->{DBI_DBH}->{Driver}->{Name} not found, no caching supported";
       $self->{DBI_DT} = undef;
       $self->{DBI_MODIFIEDFIELD} = '';
    }

    my $modified = '';
    $modified = ", $self->{DBI_MODIFIEDFIELD}" if($self->{DBI_MODIFIEDFIELD});
    $self->{DBI_QUERY}         ||= "SELECT $self->{DBI_TMPLFIELD} $modified FROM $self->{DBI_TABLE} WHERE $self->{DBI_FILEFIELD} = ?";
    $self->{DBI_STH} = $self->{DBI_DBH}->prepare_cached($self->{DBI_QUERY}) or
        return $self->error("DBI:Failed to prepare query: $DBI:errstr");
    return $self->SUPER::_init();
}

sub fetch
{
    # called to fetch template by name
    # return (undef. status_declined) on missing (and on error & tolerant)
    # return ($error, status_error) on error

    my ($self, $name) = @_;
    my ($data, $error);
    # we dont do refs or handles:
    return (undef, Template::Constants::STATUS_DECLINED) if(ref($name));

    # Check if caching is allowed / file has been cached
#    my $compiled = $self->_compiled_filename($name);
    if(defined $self->{ SIZE } && $self->{ LOOKUP }->{ $name })
    {
        ($data, $error) = _fetch($name);
    }
    else
    {
        ($data, $error) = $self->_load($name);
        ($data, $error) = $self->_compile($data) unless($error);
        $data = $self->_store($name, $data) unless($error);
    }
    
    return ($data, $error);
    
}

sub _load
{
    my ($self, $name) = @_;

    my $data = {};
    # fetch template from db
    $self->{DBI_STH}->execute($name);
    my ($templ, $modified) = $self->{DBI_STH}->fetchrow_array();
    return (undef, Template::Constants::STATUS_DECLINED) 
        if(!defined $templ);
    if($modified && exists $self->{DBI_DT})
    {
        # No "modified" field used, as we have no DT::Format::X
        $data->{time} = $self->convert_timestamp($modified);
    }
    else
    {
        $data->{time} = time();
    }
    $data->{load} = time();
    $data->{name} = $name;
    $data->{text} = $templ;

    my $err = $DBI::errstr if(!$templ);

    return ($data, $err);
}

## _store uses stat on the filename, bah
## patch to call _mtime($name) ?

sub _modified
{
    my ($self, $name) = @_;

    if(!defined $self->{DBI_DT})
    {
        return time();
    }

    my $sth = $self->{DBI_DBH}->prepare_cached(<<SQL);
SELECT $self->{DBI_MODIFIEDFIELD} 
FROM $self->{DBI_TABLE}
WHERE $self->{DBI_FILEFIELD} = ?
SQL

    $sth->execute($name);
    my ($result) = $sth->fetchrow_array();

    return $self->convert_timestamp($result) || $result;

}

sub convert_timestamp
{
    my ($self, $timestamp) = @_;

    return time() if(!$timestamp);
    if($self->{DBI_DT} && $self->{DBI_DT}->can('parse_timestamp'))
    {
        my $dt = $self->{DBI_DT}->parse_timestamp($timestamp);
        return $dt->epoch;
    }
    elsif($self->{DBI_DT} && $self->{DBI_DT}->can('format_datetime'))
    {
        my $dt = $self->{DBI_DT}->parse_datetime($timestamp);
        return $dt->epoch;
    }
    return 0;
}


1;

__END__

=head1 NAME

Template::Provider::DBI - A class to allow retrieval of templates from a DB

=head1 VERSION

This documentation refers to version 0.01.

=head1 SYNOPSIS

  use Template::Provider::DBI;
  use DBI;

  my $dbh = DBI->connect('dbi:SQLite:./mydatabase.db');
  my $dbi = Template::Provider::DBI->new({ DBI_DBH => $dbh });

  my $tt = Template->new({ LOAD_TEMPLATES => [ $dbi ] });
  $tt->process('mytemplate.tt', \%vars);

=head1 DESCRIPTION

This class adds a provider to Template Toolkit to retrieve templates from a
database of your choice. Using the LOAD_TEMPLATES option to L<Template>,
multiple providers can be created and used. The DBI provider searches for the
given template name, and returns DECLINED when it can't find it, to allow
other providers to be checked.

=head2 Caching

Caching is supported if L<DateTime::Format::DBI> supports your database. The
DateTime formatter/parser is used to convert timestamps out of the database
into epoch times for Template Toolkit. Caching is done through the usual
Template Provider method of storing the compiled template in a file.

=head2 Usage

To use this module, create an instance of it (see L<new> below), and pass it
to Template Toolkit's LOAD_TEMPLATES option. If you want to use other template
providers as well (even the default file template), then you need to also
create instances of them, and pass them to LOAD_TEMPLATES in the order you
would like them to be checked.

=head1 SUBROUTINES/METHODS

=head2 new (constructor)

Parameters:
    \%options

Many options are supported, most have defaults:

=over 4

=item DBI_DBH

A DBI database handle object, as returned by C<< DBI->connect >>. This
argument is optional if you are providing a DBI_DSN argument.

=item DBI_DSN

A database source name, to be passed to C<< DBI->connect >>. This will be used
to make and store a local database handle. It is optional if a DBI_DBH is
provided, if both are provided, an error is thrown.

=item DBI_TABLE

The name of the database table containing your templates. This will default to
'templates' if not provided.

=item DBI_TMPLFIELD

The name of the table field containing the actual template data. This will
default to 'template' if not provided.

=item DBI_FILEFIELD

The name of the table field containing the template filename. This will
default to 'filename'.

=item DBI_MODIFIEDFIELD

The name of the table field containing the timestamp or datetime of when the
template data was last modified. Defaults to 'modified' if not provided.

=item DBI_DT

If L<DateTime::Format::DBI> does not support your database, then you can try
getting around it by providing an object in the DBI_DT option that has a
"parse_timestamp" method, which will be passed the contents of your
DBI_MODIFIEDFIELD. 

=item DBI_QUERY

The query used to retrieve the template data from the database will be create
simply as: 

 SELECT $self->{DBI_TMPLFIELD}, $self->{DBI_MODIFIEDFIELD}$modified FROM $self->{DBI_TABLE} WHERE $self->{DBI_FILEFIELD} = ?;

If you need a more complex query then provide it here, it should return at
least the template data field first, then the modify date field next (or
NULL), in that order.

=back

=head1 DEPENDENCIES

Modules used, version dependencies, core yes/no

DBI

DateTime::Format::DBI

=head1 NOTES

DateTime::Format::DBI produces DBI warnings when used with SQLite. It calls
DBI::_dbtype_names($dbh); .. Not my fault, honest!

=head1 BUGS AND LIMITATIONS

None known currently, please email the author if you find
any.

=head1 AUTHOR

Jess Robinson <cpan@desert-island.demon.co.uk>

=cut
