package Plack::Middleware::TMT;
use strict;
use warnings;
BEGIN {
  $Plack::Middleware::TMT::VERSION = '0.04';
}
use Carp qw/croak/;
use parent 'Plack::Middleware';
use Text::MicroTemplate::File;
use Plack::Request;
use Data::Dumper;
use Plack::Util::Accessor qw/
    tmt
    include_path default_tmpl tmpl_extension
    use_cache
    content_type default_content_type
    macro package_name
    pass_through
/;

sub prepare_app {
    my $self = shift;

    $self->default_tmpl('index') if !$self->default_tmpl;
    $self->default_content_type('text/html') if !$self->default_content_type;
    $self->pass_through(0) if !$self->pass_through;

    $self->tmt(
        Text::MicroTemplate::File->new(
            include_path => $self->include_path,
            use_cache    => $self->use_cache,
            package_name => $self->package_name,
        )
    );

    $self->macro(+{}) if !$self->macro;
    warn 'macro "d" is reserved. it works as dumper.' if $self->macro->{d};
    $self->macro->{d} = sub {
        local $Data::Dumper::Terse    = 1;
        local $Data::Dumper::Indent   = 1;
        local $Data::Dumper::Sortkeys = 1;
        Data::Dumper::Dumper(shift);
    };

    for my $name (keys %{ $self->macro }) {
        unless ($name =~ /^[a-zA-Z_][a-zA-Z0-9_]*$/) {
            croak qq{Invalid macro key name: "$name"};
        }
        no strict 'refs'; ## no critic
        no warnings 'redefine';
        my $code = $self->{macro}{$name};
        *{ $self->tmt->package_name . "::$name" }
            = ref $code eq 'CODE' ? $code : sub {$code};
    }
}

sub call {
    my ( $self, $env ) = @_;

    my $res = $self->_handle_template($env);

    if ( $res && not( $self->pass_through and $res->[0] == 404 ) ) {
        return $res;
    }
    if ( $self->app ) {
        $res = $self->app->($env);
    }

    $res;
}

sub _handle_template {
    my ($self, $env) = @_;

    my $req = Plack::Request->new($env);

    my $tmpl = $req->path eq '/'
             ? $self->default_tmpl
             : $req->path =~ m!/$!
             ? $req->path. $self->default_tmpl
             : $req->path;
    $tmpl =~ s!^/!!;

    my $ext = $self->tmpl_extension || '';

    if (!-e $self->include_path. '/'. "$tmpl$ext") {
        return [404, ['Content-Type' => 'text/plain'], ['Not Found']];
    }

    $self->process_template(
        "$tmpl$ext",
        200,
        $req,
    );
}

sub process_template {
    my ( $self, $template, $status_code, $vars ) = @_;

    my $content_type = $self->content_type || $self->default_content_type;
    my $content = $self->tmt->render_file($template, $vars)->as_string;

    return [ $status_code, [ 'Content-Type' => $content_type ], [$content] ];
}

1;

__END__

=head1 NAME

Plack::Middleware::TMT - Text::MicroTemplate on the Plack


=head1 SYNOPSIS

    enable 'TMT',
        include_path => 'tmpl';

support few options

    enable 'TMT',
        include_path   => 'tmpl',
        tmpl_extension => '.mt',
        pass_through   => 1,
        macro => +{
            hello => sub { 'hello!' },
        };

=head1 DESCRIPTION

when you write tiny web app, you want to write some perl codes in template files.
it sounds evil.
you can use this module for test or micro app with yourself.

for example index.psgi

    use strict;
    use warnings;
    use Plack::Builder;

    builder {
        mount '/' => builder {
            enable 'TMT',
                include_path => '/path/to/tmpl/dir',
                tmpl_extension => '.mt';
        };
    };

and /path/to/tmpl/dir/index.mt like below

    ? my $r = shift; # Plack::Request Obj

    <pre>
        <?= d($r) ?>
    </pre>

`d` is reserved macro. it works as dumper function.

then you can plackup

    $ plackup index.psgi

finally, you can browse http://localhost:5000/


=head1 METHOD

=over

=item call

=item prepare_app

=item process_template

=back


=head1 REPOSITORY

Plack::Middleware::TMT is hosted on github
<http://github.com/bayashi/Plack-Middleware-TMT>


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Text::MicroTemplate::File>, L<Text::MicroTemplate>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
