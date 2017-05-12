package Silki::Schema::File;
{
  $Silki::Schema::File::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use File::MimeInfo qw( describe );
use List::AllUtils qw( any );
use Silki::Config;
use Silki::I18N qw( loc );
use Silki::Schema;
use Silki::Types qw( Bool );

use Fey::ORM::Table;

with 'Silki::Role::Schema::URIMaker';

with 'Silki::Role::Schema::SystemLogger' => { methods => ['delete'] };

with 'Silki::Role::Schema::DataValidator' => {
    steps => [
        '_filename_is_unique_for_page',
    ],
};

my $Schema = Silki::Schema->Schema();

has_policy 'Silki::Schema::Policy';

has_table( $Schema->table('File') );

has_one( $Schema->table('User') );

has_one page => (
    table   => $Schema->table('Page'),
    handles => ['wiki'],
);

has is_displayable_in_browser => (
    is       => 'ro',
    isa      => Bool,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_is_displayable_in_browser',
);

has is_browser_displayable_image => (
    is       => 'ro',
    isa      => Bool,
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_is_browser_displayable_image',
);

with 'Silki::Role::Schema::File';

with 'Silki::Role::Schema::Serializes' => {
    skip => ['contents'],
};

sub _system_log_values_for_delete {
    my $self = shift;

    my $msg
        = 'Deleted file, '
        . $self->filename()
        . ', attached to '
        . $self->page()->title() . ' in '
        . $self->wiki()->title();

    return (
        page_id   => $self->page_id(),
        message   => $msg,
        data_blob => {
            filename  => $self->filename(),
            mime_type => $self->mime_type(),
            file_size => $self->file_size(),
        },
    );
}

sub _filename_is_unique_for_page {
    my $self      = shift;
    my $p         = shift;
    my $is_insert = shift;

    return
        if !$is_insert
            && exists $p->{filename}
            && $p->{filename} eq $self->filename();

    return unless exists $p->{filename};

    return
        unless __PACKAGE__->new(
        filename => $p->{filename},
        page_id  => $p->{page_id},
        );

    return {
        message => loc(
            'The filename you provided is already in use for another file on this page.'
        ),
    };
}

sub _base_uri_path {
    my $self = shift;

    return $self->wiki()->_base_uri_path() . '/file/' . $self->file_id();
}

sub mime_type_description_for_lang {
    my $self = shift;
    my $lang = shift;

    my $desc = describe( $self->mime_type(), $lang );
    $desc ||= describe( $self->mime_type() );

    return $desc;
}

{
    my %browser_image = map { $_ => 1 } qw( image/gif image/jpeg image/png );

    sub _build_is_browser_displayable_image {
        return $browser_image{ $_[0]->mime_type() };
    }
}

{
    my @displayable = (
        qr{^text/},
        qr{^application/ecmascript$},
        qr{^application/javascript$},
        qr{^application/x-httpd-php.*},
        qr{^application/x-perl$},
        qr{^application/x-ruby$},
        qr{^application/x-shellscript$},
        qr{^application/sgml},
        qr{^application/xml},
        qr{^application/.+\+xml$}
    );

    sub _build_is_displayable_in_browser {
        my $self = shift;

        my $type = $self->mime_type();

        return $self->is_browser_displayable_image()
            || any { $type =~ $_ } @displayable;
    }
}

around _build_small_image_file => sub {
    my $orig = shift;
    my $self = shift;

    return unless $self->is_browser_displayable_image();

    return $self->$orig(@_);
};

around _build_thumbnail_file => sub {
    my $orig = shift;
    my $self = shift;

    return unless $self->is_browser_displayable_image();

    return $self->$orig(@_);
};

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents a file

__END__
=pod

=head1 NAME

Silki::Schema::File - Represents a file

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

