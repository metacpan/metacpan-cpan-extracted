package Nephia;
use 5.008005;
use strict;
use warnings;
use Nephia::Incognito;

our $VERSION = "0.87";

sub import {
    my ($class, %opts) = @_;
    my $caller = caller;
    Nephia::Incognito->incognito(%opts, caller => $caller);
}

sub call {
    my ($class, $codepath) = @_;
    my $caller = caller;
    Nephia::Incognito->unmask($caller)->call($codepath);
}

sub run {
    my $caller = caller;
    Nephia::Incognito->unmask($caller)->run(@_);
}

1;
__END__

=encoding utf-8

=head1 NAME

Nephia - A microcore architecture WAF

=head1 SYNOPSIS

    use Nephia plugins => [...];
    app {
        my $req  = req;         ### Request object
        my $id   = param('id'); ### query-param that named "id" 
        my $body = sprintf('ID is %s', $id);
        [200, [], $body];
    };

=head1 DESCRIPTION

Nephia is microcore architecture WAF. 

=head1 GETTING STARTED

Let's try to create your project.

    nephia-setup YourApp::Web

Then, you may plackup on your project directory.

Please see L<Nephia::Setup::Plugin::Basic> for detail.

=head1 BOOTSTRAP A MINIMALIST STRUCTURE

Use "--plugins Minimal" option to minimalistic setup.

    nephia-setup --plugins Minimal YourApp::Mini

Please see L<Nephia::Setup::Plugin::Minimal> for detail.

=head1 LOAD OPTIONS 

Please see L<Nephia::Core>.

=head1 DSL

=head2 app

    app { ... };

Specify code-block of your webapp.

=head2 other two basic DSL

Please see L<Nephia::Plugin::Basic>.

=head2 dispatcher DSL

Please see L<Nephia::Plugin::Dispatch>.

=head1 EXPORTS

=head2 run

In app.psgi, run() method returns your webapp as coderef.

    use YourApp::Web;
    YourApp::Web->run;

=head1 CLASS METHOD

=head2 call

Returns external logic as coderef.

    my $external_logic = Nephia->call('C::Root#index');

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

