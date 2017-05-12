use strict;   # make perlcritic happy about the $VERSION that
use warnings; # Dist::Zilla::Plugin::PkgVersion inserts

package Template::Provider::PrefixDBIC;
BEGIN {
  $Template::Provider::PrefixDBIC::VERSION = '0.01';
}

use parent 'Template::Provider::DBIC';

sub _init {
    my ( $self, $options ) = @_;

    $self->{ COLUMN_PREFIX }   = $options->{ COLUMN_PREFIX }   || 'prefix';
    $self->{ PREFIXES }        = $options->{ PREFIXES }        || '';

    unless(ref($self->{ PREFIXES })) {
        $self->{ PREFIXES } = [ $self->{ PREFIXES } ];
    }

    if($options->{ SCHEMA }) {
        return $self->error(
            __PACKAGE__ . ' does not support the SCHEMA option'
        );
    }
    unless($options->{ RESULTSET }) {
        return $self->error("You must provide a DBIx::Class::ResultSet to new");
    }

    return $self->SUPER::_init($options);
}

sub prefixes {
    my $self = shift;

    if(@_) {
        my $new_prefixes    = shift;
        $new_prefixes       = [ $new_prefixes ] unless ref $new_prefixes;
        $self->{ PREFIXES } = $new_prefixes;
    }
    return $self->{ PREFIXES };
}

sub _get_matching_row {
    my ( $self, $name ) = @_;

    my $prefixes             = $self->prefixes;
    my $rs                   = $self->{ RESULTSET };
    my $name_column          = $self->{ COLUMN_NAME };
    my $path_column          = $self->{ COLUMN_PREFIX };
    my $original_path_column = $path_column;

    $name_column = 'me.' . $name_column unless $name_column =~ /\./;
    $path_column = 'me.' . $path_column unless $path_column =~ /\./;

    my @results     = $rs->search({
        $name_column => $name,
        $path_column => {'-in' => $prefixes },
    });

    unless(@results) {
        return;
    }

    if(@results > 1) {
        my $i     = 0;
        my %path_positions = map { $_ => $i++ } @$prefixes;

        @results = sort {
            $path_positions{$a->get_column($original_path_column)}
            <=>
            $path_positions{$b->get_column($original_path_column)}
        } @results;
    }

    return $results[0]; # first in the path list
}

sub fetch {
    my ( $self, $name ) = @_;

    my $compiled_filename = $self->_compiled_filename($name);

    my ( $data, $error ) = $self->_load($name);
    unless($error) {
        ( $data, $error ) = $self->_compile($data, $compiled_filename);
    }
    $data = $data->{ data } unless $error;

    return ( $data, $error );
}

sub _load {
    my ( $self, $name ) = @_;

    my $content_column  = $self->{ COLUMN_CONTENT };
    my $modified_column = $self->{ COLUMN_MODIFIED };

    my $row = $self->_get_matching_row($name);

    unless($row) {
        return ( undef, Template::Constants::STATUS_DECLINED );
    }

    return ({
        name => $name,
        text => $row->get_column($content_column),
        time => Date::Parse::str2time($row->get_column($modified_column)),
        load => time,
    }, undef);
}

sub _template_modified {
    my ( $self, $name ) = @_;

    my $row = $self->_get_matching_row($name);

    unless($row) {
        return;
    }
    my $mtime = $row->get_column($self->{ COLUMN_MODIFIED });
    $mtime = '0E0' if $mtime == 0;
    return $mtime;
}

1;

# ABSTRACT: A template provider that uses DBIC for database access and exhibits fallback functionality



=pod

=head1 NAME

Template::Provider::PrefixDBIC - A template provider that uses DBIC for database access and exhibits fallback functionality

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  use MySchema;
  use Template;
  use Template::Provider::PrefixDBIC;

  my $schema   = MySchema->connect(...);
  my $provider = Template::Provider::PrefixDBIC->new(
    RESULTSET => $schema->resultset(...),
    PREFIXES  => ['foo', 'default'],
  );

  my $template = Template->new({
    LOAD_TEMPLATES => [
        $provider,
    ],
  });

  $template->process('my_template'); # tries prefix = 'foo', name = 'my_template', then
                                     # prefix = 'default', name ='my_template'

=head1 DESCRIPTION

Template::Provider::PrefixDBIC combines the fallback functionality of
L<Template::Provider> along with the database access of
L<Template::Provider::DBIC>.

If you don't need the fallback functionality, I highly recommend
the L<Template::Provider::DBIC> module.

Because it makes use of the full name of the template, we don't extract
a table name from the template name, and the SCHEMA option to the constructor
is thus unsupported, unlike in L<Template::Provider::DBIC>.

=head1 OPTIONS

In addition to the options provided by L<Template::Provider::DBIC>
(with the exception of SCHEMA), Template::Provider::PrefixDBIC also provides
the following options:

=head2 COLUMN_PREFIX

The table column that contains the prefix for a template entry.  This defaults
to 'prefix'.

=head2 PREFIXES

The list of prefixes that will be used to look up a template.  If a string is
provided, it is converted to a single-element array reference.  Defaults to
C<['']>.

=head1 METHODS

=head2 $self->prefixes

=head2 $self->prefixes($new_prefixes)

When called with no arguments, this method returns the list of prefixes that
will be used to look up a template.  When called with a C<$new_prefixes>
argument, the internal list is replaced with C<$new_prefixes>.
C<$new_prefixes> is automatically converted to an array reference if it isn't
one.

=head1 CAUTION

If your prefix + name combination does not fall under a unique constraint in
your database, this module could encounter multiple results for any given
prefix/name combination.  This module does no extra work to disambiguate; it
will simply pick the first one that your database would return from the
SELECT, whatever that might be.

Also, this provider implementation doesn't do any caching.  I wrote this module
because we need to invoke certain templates based on which customer is accessing
a resource, and fallback to a default if there is no customer-specific behavior.
I'd rather not let caching leak customer details; maybe I'll add it in a later
release.

=head1 SEE ALSO

L<Template>, L<Template::Provider>, L<Template::Provider::DBIC>

=head1 AUTHOR

Rob Hoelz <rhoelz@inoc.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by INOC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

