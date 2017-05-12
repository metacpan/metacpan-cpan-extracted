package PAD;
use strict;
use warnings;
our $VERSION = '0.04';
use Plack::Request;
use Plack::App::Directory;

sub new {
    my ($class, %args) = @_;
    my $plugin = $args{plugin};

    __PACKAGE__->require($plugin);

    bless {
        plugin => $plugin,
        args   => \%args,
    }, $class;
}

sub plugin { shift->{plugin} }

sub psgi_app {
    my $self = shift;

    return sub {
        my $req  = Plack::Request->new(shift);

        my $path = $req->path_info;
        $path =~ s/[\/\\\0]//g;
        if ($path eq '/' || $path eq 'favicon.ico' || not $path) {
            return Plack::App::Directory->new->to_app->($req->env);
        }

        my $plugin = $self->plugin->new(
            %{ $self->{args} },
            request => $req,
        );

        return $req->path_info =~ $plugin->suffix
            ? $plugin->execute
            : Plack::App::Directory->new->to_app->($req->env);
    };
}

sub require {
    my (undef, $class) = @_;
    unless ($class->can("new")) {
        my $path = $class;
        $path =~ s|::|/|g;
        require "$path.pm"; ## no critic
    }
}

1;
__END__

=head1 NAME

PAD - create PSGI app that serve filtered files

=head1 SYNOPSIS

    use PAD;
    my $pad = PAD->new(plugin => $class);
    my $app = $pad->psgi_app;

=head1 DESCRIPTION

PAD is useful HTTP server 

=head1 AUTHOR

punytan E<lt>punytan@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
