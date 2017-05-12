package Mojolicious::Plugin::ServerInfo;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.010';

sub register {
  my ($self, $app) = @_;

  push @{$app->renderer->classes}, __PACKAGE__;
  push @{$app->static->classes},   __PACKAGE__;
  $app->routes->any('/serverinfo' => sub { shift->render } );
}

1;

=head1 NAME

Mojolicious::Plugin::ServerInfo - display Server and Perl environment data

=begin html

<a href="https://travis-ci.org/wollmers/Mojolicious-Plugin-ServerInfo"><img src="https://travis-ci.org/wollmers/Mojolicious-Plugin-ServerInfo.svg?branch=master" alt="Mojolicious-Plugin-ServerInfo"></a>
<a href='https://coveralls.io/r/wollmers/Mojolicious-Plugin-ServerInfo'><img src='https://coveralls.io/repos/wollmers/Mojolicious-Plugin-ServerInfo/badge.svg' alt='Coverage Status' /></a>
<a href='http://cpants.cpanauthors.org/dist/Mojolicious-Plugin-ServerInfo'><img src='http://cpants.cpanauthors.org/dist/Mojolicious-Plugin-ServerInfo.png' alt='Kwalitee Score' /></a>
<a href="http://badge.fury.io/pl/Mojolicious-Plugin-ServerInfo"><img src="https://badge.fury.io/pl/Mojolicious-Plugin-ServerInfo.svg" alt="CPAN version" height="18"></a>

=end html

=head1 SYNOPSIS

 $app->plugin('Mojolicious::Plugin::ServerInfo');


=head1 DESCRIPTION

L<Mojolicious::Plugin::ServerInfo> is a Mojolicious-Plugin.

It creates a route

  /serverinfo

where detailed info is displayed in formatted HTML.

=head2 METHODS

=over 4


=item register

Do not use directly. It is called by Mojolicious.

=back

=head1 SEE ALSO

=over

=item *

L<Mojolicious>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/wollmers/Mojolicious-Plugin-ServerInfo>

=head1 AUTHOR

Helmut Wollmersdorfer, E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=begin html

<a href='http://cpants.cpanauthors.org/author/wollmers'><img src='http://cpants.cpanauthors.org/author/wollmers.png' alt='Kwalitee Score' /></a>

=end html

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2015 by Helmut Wollmersdorfer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


__DATA__

@@ serverinfo.css

body {
    background-color: #fff;
    color: #333;
    font-family: "Helvetica Neue",Helvetica,Arial,sans-serif;
    font-size: 0.9em;
    line-height: 1.5em;
    margin: 0;
}
html {
    font-size: 100%;
}
h1, h2, h3, h4, h5, h6 {
    color: inherit;
    font-family: inherit;
    font-weight: bold;
    line-height: 1;
    margin: 10px 0;
    text-rendering: optimizelegibility;
}
h1 {
  font-size: 1.5em;
  line-height: 1.7em;
}
h2 {
  font-size: 1.3em;
  line-height: 1.7em;
}
table {
  border-collapse: collapse;
  width: 100%;
}
table.striped {
  background-color: #fff;
  border: 1px solid #ddd;
  overflow: hidden;
  padding: 1em;
}
th, td {
    border-left: 1px solid #ddd;
    border-top: 1px solid #ddd;
    line-height: 20px;
    text-align: left;
    vertical-align: top;
    padding: 4px 5px;
}
th {
    font-weight: bold;
}

.striped tr:nth-child(odd) th,
.striped tr:nth-child(odd) td {
  background-color: #f9f9f9
}
.striped tr:nth-child(even) th,
.striped tr:nth-child(even) td {
  background-color: #fff
}
.striped { border-top: solid #ddd 1px }

.container {
  max-width: 1000px;
  margin: 0 auto;
}

@@ serverinfo.html.ep
<!DOCTYPE html>
<html>
<head>
<title>Serverinfo</title>
<link media="screen, print, projection" type="text/css" rel="stylesheet" href="/serverinfo.css">
</head>
<body>
<div class="container">

<h1>Serverinfo</h1>

<h2>%ENV</h2>

%= tag table => class => "striped" => begin
  %= tag tr => begin
    % for my $header (qw(key value)) {
      %= tag th =>  $header
    % }
  %= end
  % for my $key (sort keys %ENV) {
      %= tag tr => begin
        %= tag td =>  $key
        %= tag td =>  $ENV{$key} // ''
      %= end
  % }
%= end


<h2>Perl @INC</h2>

%= tag table => class => "striped" => begin
  %= tag tr => begin
    % for my $header (qw(path)) {
      %= tag th =>  $header
    % }
  %= end
  % for my $path (@INC) {
      %= tag tr => begin
        %= tag td =>  $path // ''
      %= end
  % }
%= end

<h2>Perl %INC</h2>

%= tag table => class => "striped" => begin
  %= tag tr => begin
    % for my $header (qw(file version path)) {
      %= tag th =>  $header
    % }
  %= end
  % for my $key (sort keys %INC) {
      % my $module = $key;
      % $module =~ s{\/}{::}gsmx;
      % $module =~ s/.pm$//g;
      % my $version;
      % { no strict 'refs';
        % $version = ${$module . "::VERSION"} || '';
      % }
      %= tag tr => begin
        %= tag td =>  $key
        %= tag td =>  $version
        %= tag td =>  $INC{$key} // ''
      %= end
  % }
%= end

<p>Number of modules: <%= scalar keys %INC %></p>

</div>
</body>
</html>

__END__


