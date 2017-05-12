package Plack::Middleware::JavaScript::Ectype;

use strict;
use warnings;
use parent qw/Plack::Middleware/;
use HTTP::Date;
use Plack::Util;
use Plack::Util::Accessor qw/prefix root minify/;
use Carp;
use JavaScript::Ectype::Loader;

our $VERSION = q(0.0.1);

sub call{
    my ($self,$env) = @_;
    return $self->_handler( $env ) || $self->app->($env);
}

sub expire_time{
    my $self = shift;
    return $self->{expire_time} || 60 * 60 * 24 * 14;
}

sub _handler{
    my ($self,$env) = @_;

    return unless defined $self->prefix;
    return unless defined $self->root;
    return unless my $fqn = $self->_get_fqn( $env );


    my $jel = JavaScript::Ectype::Loader->new(
        path   => $self->root,
        target => $fqn,
        minify => int($self->minify)
    );
    my $ims = $self->_get_modified_since($env) || 0;
    return $self->_not_found()    unless -e $jel->file_path;
    return $self->_not_modified() unless $jel->is_modified_from($ims);
    $jel->load_content;

    my $content = $jel->get_content;
    my $last_modified = $jel->newest_mtime;
    return [
        200,
        [
            'Content-Type'   => 'text/javascript',
            'Content-Length' => length $content,
            'Last-Modified'  => HTTP::Date::time2str($last_modified),
            'Expires'        => HTTP::Date::time2str( time() + $self->expire_time )
        ],
        [$content]
    ];

}
sub _not_found {
    my ($self) = @_;
    return [404,[],[]];
}

sub _not_modified {
    my ($self ) = @_;
    return [304,[Expires => HTTP::Date::time2str( time() + $self->expire_time )],[]]
}

sub _get_fqn {
    my ( $self, $env ) = @_;
    my $uri    = $env->{REQUEST_URI};
    my $prefix = $self->prefix;
    if ( $uri =~ m/$prefix([a-zA-Z0-9._]+)/ ){
        return $1;
    }
    return;
}

sub _get_modified_since{
    my ($self,$env) = @_;
    return HTTP::Date::str2time( $env->{HTTP_IF_MODIFIED_SINCE} );
}

1; 
__END__

__END__
=head1 NAME

Plack::Middleware::JavaScript::Ectype  - An Plack Middleware JavaScript Preprocessor designed for large scale javascript development

=head1 SYNOPSYS

    # in apps.psgi
    builder {
        enable "Plack::Middleware::JavaScript::Ectype",
            root => '$DOCUMENT_ROOT/static/js/',prefix => '/ectype/',minify => 1;
        sub {
            [200,['Content-Type'=> 'text/plain','Content-Length'=> 2],['ok']]
        }
    };

For example , you access http://example.com/ectype/org.cpan.ajax,
get response $DOCUMENT_ROOT/static/js/org/cpan/ajax.js converted by JavaScript::Ectype.

=head1 VARIABLES

you can set some variables to control JavaScript::Ectype.

=head2 root

EctypeLibPath is where javascript files are.

=head2 prefix

prefix is url prefix.

=head2 minify

minify is whether minify javascript code or not.

=head1 AUTHOR

Daichi Hiroki, C<< <hirokidaichi<AT>gmail.com> >>

=head1 SEE ALSO

L<JavaScript::Ectype>

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Daichi Hiroki.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


