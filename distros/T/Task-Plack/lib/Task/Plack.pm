package Task::Plack;

use strict;
use 5.008_001;
our $VERSION = '0.28';
use ExtUtils::MakeMaker;

use base qw(Exporter);
our @EXPORT = qw(git_clone);

sub dependencies {
    return (
        'FastCGI daemon and dispatcher', 1, [
            [ 'FCGI' ],
            [ 'FCGI::Client' ],
            [ 'FCGI::ProcManager' ],
            [ 'Net::FastCGI' ],
        ],
        'Stacktrace with lexical variables', 0, [
            [ 'Devel::StackTrace::WithLexicals', 0.08 ],
        ],
        'Utility to create IO::Handle-ish objects', 1, [
            [ 'IO::Handle::Util' ],
        ],
        'Core and Essential Tools', 1, [
            [ 'PSGI',  'git://github.com/miyagawa/psgi-specs.git' ],
            [ 'Plack', 'git://github.com/miyagawa/Plack.git' ],
            [ 'CGI::PSGI', 'git://github.com/miyagawa/CGI-PSGI.git' ],
            [ 'CGI::Emulate::PSGI', 'git://github.com/tokuhirom/p5-cgi-emulate-psgi.git' ],
            [ 'CGI::Compile', 'git://github.com/miyagawa/CGI-Compile.git' ],
        ],
        'Recommended PSGI Servers and Plack handlers', 1, [
            [ 'HTTP::Server::Simple::PSGI', 'git://github.com/miyagawa/HTTP-Server-Simple-PSGI.git' ],
            [ 'Starman', 'git://github.com/miyagawa/Starman.git' ],
            [ 'Twiggy', 'git://github.com/miyagawa/Twiggy.git' ],
            [ 'Starlet', 'git://github.com/kazuho/Starlet.git' ],
            [ 'Corona', 'git://github.com/miyagawa/Corona.git' ],
        ],
        'Extra PSGI servers and Plack handlers', 0, [
            [ 'Plack::Handler::AnyEvent::ReverseHTTP', 'git://github.com/miyagawa/Plack-Handler-AnyEvent-ReverseHTTP.git' ],
            [ 'Plack::Handler::SCGI', 'git://github.com/miyagawa/Plack-Handler-SCGI.git' ],
            [ 'Plack::Handler::AnyEvent::SCGI', 'git://github.com/miyagawa/Plack-Handler-AnyEvent-SCGI.git' ],
            [ 'Plack::Handler::AnyEvent::HTTPD', 'git://github.com/miyagawa/Plack-Handler-AnyEvent-HTTPD.git' ],
            [ 'Perlbal::Plugin::PSGI', 'git://github.com/miyagawa/Perlbal-Plugin-PSGI.git' ],
        ],
        'In-Development PSGI Servers', 0, [
            [ undef, 'Plack::Server::Danga::Socket', 'git://github.com/typester/Plack-Server-Danga-Socket.git' ],
            [ undef, 'Plack::Server::FCGI::EV', 'git://github.com/mala/Plack-Server-FCGI-EV.git' ],
            [ undef, 'mod_psgi', 'git://github.com/spiritloose/mod_psgi.git' ],
            [ undef, 'evpsgi', 'git://github.com/sekimura/evpsgi.git' ],
            [ undef, 'nginx', 'git://github.com/yappo/nginx-psgi-patchs.git' ],
        ],
        'Recommended middleware components', 1, [
            [ 'Plack::Middleware::Deflater', 'git://github.com/miyagawa/Plack-Middleware-Deflater.git' ],
            [ 'Plack::Middleware::Session', 'git://github.com/stevan/plack-middleware-session.git' ],
            [ 'Plack::Middleware::Debug', 'git://github.com/miyagawa/Plack-Middleware-Debug.git' ],
            [ 'Plack::Middleware::Header', 'git://github.com/nihen/Plack-Middleware-Header.git' ],
            [ 'Plack::Middleware::Auth::Digest', 'git://github.com/miyagawa/Plack-Middleware-Auth-Digest.git' ],
            [ 'Plack::App::Proxy', 'git://github.com/leedo/Plack-App-Proxy.git' ],
            [ 'Plack::Middleware::ReverseProxy', 'git://github.com/lopnor/Plack-Middleware-ReverseProxy.git' ],
            [ 'Plack::Middleware::ConsoleLogger', 'git://github.com/miyagawa/Plack-Middleware-ConsoleLogger.git' ],
        ],
        'Extra Middleware Components', 0, [
            [ 'Plack::Middleware::JSConcat', 'git://github.com/clkao/Plack-Middleware-JSConcat.git' ],
            [ 'Plack::Middleware::Throttle', 'git://github.com/franckcuny/plack--middleware--throttle.git' ],
            [ 'Plack::Middleware::Status', 'git://github.com/pdonelan/Plack-Middleware-Status.git' ],
            [ 'Plack::Middleware::AutoRefresh', 'git://github.com/mvgrimes/Plack-Middleware-AutoRefresh.git' ],
            [ undef, 'Plack::Middleware::Rewrite', 'git://github.com/snark/Plack-Middleware-Rewrite.git' ],
            [ undef, 'Plack::Middleware::MobileDetector', 'git://github.com/snark/Plack-Middleware-MobileDetector.git' ],
            [ undef, 'Plack::Middleware::FirePHP', 'git://github.com/fhelmberger/Plack-Middleware-FirePHP.git' ],
            [ 'Plack::Middleware::File::Sass', 'git://github.com/miyagawa/Plack-Middleware-File-Sass.git' ],
            [ undef, 'Plack::Middleware::ForgeryProtection', 'git://github.com/jyotty/Plack-Middleware-ForgeryProtection.git' ],
        ],
        'Tools', 0, [
            [ 'Test::WWW::Mechanize::PSGI', 'git://github.com/acme/test-www-mechanize-psgi.git' ],
            [ 'Flea', 'git://github.com/frodwith/flea.git' ],
        ],
        'Catalyst Engine', 0, [
            [ 'Catalyst::Engine::PSGI', 'git://github.com/miyagawa/Catalyst-Engine-PSGI.git' ],
        ],
        'Squatting::On', 0, [
            [ 'Squatting::On::PSGI', 'git://github.com/beppu/Squatting-On-PSGI.git' ],
        ],
        'Sledge', 0, [
            [ undef, 'Sledge::PSGI', 'git://github.com/mala/Sledge-PSGI.git' ],
        ],
        'CGI::Application::PSGI', 0, [
            [ 'CGI::Application::PSGI', 'git://github.com/markstos/CGI-Application-PSGI.git' ],
        ],
        'Maypole::PSGI', 0, [
            [ undef, 'Maypole::PSGI', 'git://github.com/miyagawa/Maypole-PSGI.git' ],
        ],
        'Mason PSGI handler', 0, [
            [ undef, 'HTML::Mason::PSGIHandler', 'git://github.com/rjbs/HTML-Mason-PSGIHandler.git' ],
        ],
    );
}

sub has_module {
    my $file = shift;
    $file =~ s!::!/!g;
    scalar grep -e "$_/$file.pm", @INC;
}

sub iter_deps {
    my($class, $cb) = @_;
    my @deps = $class->dependencies;
    while (my($name, $cond, $deps) = splice @deps, 0, 3) {
        $cb->($name, $cond, $deps);
    }
}

sub cpanfile {
    my $class = shift;
    my $fh = shift;

    $class->iter_deps(sub {
        my($name, $cond, $deps) = @_;
        my @modules = grep defined, map $_->[0], @$deps;
        if ($cond) {
            for my $module (@modules) {
                $fh->print("recommends '$module', '", version_for($module), "',\n");
            }
        } else {
            (my $ident = $name) =~ s/[^A-Za-z_]+/_/g;
            $fh->print("feature '", lc($ident), "', '$name' => sub {\n");
            for my $module (@modules) {
                $fh->print("  recommends '$module', '", version_for($module), "',\n");
            }
            $fh->print("};\n");
        }
        $fh->print("\n");
    });
}

sub version_for {
    my $dist = shift;

    (my $module = $dist) =~ s/-/::/g;
    my $info = `cpanm --info $module ` or return;
    return ($info =~ /-([\d\.]+)\.tar\.gz/)[0];
}

sub git_clone {
    my @clone;
    __PACKAGE__->iter_deps(sub {
        my($name, $cond, $deps) = @_;
        my @repos = map { shift @$_ unless $_->[0]; $_ } @$deps;

        print "[$name]\n";
        for my $repo (@repos) {
            next unless $repo->[1];
            print "- $repo->[0] ($repo->[1])\n";
        }

        my $prompt = ExtUtils::MakeMaker::prompt("Want to git clone them? ", $cond ? 'y' : 'n');
        if (lc $prompt eq 'y') {
            for my $repo (@repos) {
                push @clone, $repo->[1];
            }
        }
    });

    for my $repo (@clone) {
        system "git", "clone", $repo;
    }
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Task::Plack - Plack bundle

=head1 SYNOPSIS

  cpanm --interactive Task::Plack

  # clone development git for all of those modules (You'll be prompted)
  > perl -MTask::Plack -e 'git_clone'

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://plackperl.org/>

=cut
