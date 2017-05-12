package Plack::Middleware::RevisionPlate;
use 5.010;
use strict;
use warnings;

use Plack::Util::Accessor qw/path revision_filename/;
use Plack::Response;
use File::Slurp qw/read_file/;
use parent qw/Plack::Middleware/;

our $VERSION = "0.01";

sub call {
    my $self = shift;
    my $env  = shift;
    return $self->_may_handle_request($env) // $self->app->($env);
}

sub prepare_app {
    my $self = shift;
    $self->_read_revision_file_at_first;
}

sub _read_revision_file_at_first {
    my $self = shift;
    $self->{revision} = -e $self->_revision_filename && read_file($self->_revision_filename);
}

sub _may_handle_request {
    my ($self, $env) = @_;
    my $path_match = $self->path or return;
    my $path = $env->{PATH_INFO};

    for ($path) {
        my $matched = 'CODE' eq ref $path_match ? $path_match->($_, $env) : $_ =~ $path_match;
        return unless $matched;
    }

    my $method = $env->{REQUEST_METHOD};
    return Plack::Response->new(405)->finalize if $method ne 'GET' && $method ne 'HEAD'; # 405: method not allowed

    my $res = Plack::Response->new;
    $res->content_type('text/plain');
    if (defined $self->{revision}) {
        if (-e $self->_revision_filename) {
            $res->status(200);
            $res->body($self->{revision});
        } else {
            $res->status(404);
            $res->body("REVISION_FILE_REMOVED\n");
        }
    } else {
        $res->status(404);
        $res->body("REVISION_FILE_NOT_FOUND\n");
    }

    $res->body('') if $method eq 'HEAD';
    return $res->finalize;
}

sub _revision_filename {
    my $self = shift;
    $self->{_revision_filename} //= $self->revision_filename // './REVISION';
}

1;
__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::RevisionPlate - Serves an endpoint returns application's C<REVISION>.

=head1 SYNOPSIS

    use Plack::Builder;
    use Plack::Middleware::RevisionPlate;

    builder {
        # Default revision_filename is ./REVISION.
        enable 'Plack::Middleware::RevisionPlate',
            path => '/site/sha1';

        # Otherwise you can specify revision_filename.
        enable 'Plack::Middleware::RevisionPlate',
            path => '/site/sha1/somemodule', revision_filename => './modules/hoge/REVISION';

        sub {
            my $env = shift;
            return [ 200, [], ['Hello! Plack'] ];
        };
    };

=head1 DESCRIPTION

Plack::Middleware::RevisionPlate returns content of file C<REVISION> (or the file specified by C<revision_filename> option) on GET/HEAD request to path specified C<path> option.
Content of endpoint don't changes even if C<REVISION> file changed, but returns 404 if C<REVISION> file removed.

=head1 LICENSE

MIT License

=head1 AUTHOR

Asato Wakisaka E<lt>asato.wakisaka@gmail.comE<gt>

This module is a perl port of ruby gem L<RevisionPlate|https://github.com/sorah/revision_plate> by sorah.

=cut

