package Mojolicious::Plugin::DBInfo;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.002';

sub register {
  my ($self, $app) = @_;

  push @{$app->renderer->classes}, __PACKAGE__;
  push @{$app->static->classes},   __PACKAGE__;
  $app->routes->any('/dbinfo' => sub { shift->render } );
}

1;

=head1 NAME

Mojolicious::Plugin::DBInfo - display DataBase Information

=begin html

<a href="https://travis-ci.org/wollmers/Mojolicious-Plugin-DBInfo"><img src="https://travis-ci.org/wollmers/Mojolicious-Plugin-DBInfo.svg?branch=master" alt="Mojolicious-Plugin-DBInfo"></a>
<a href='https://coveralls.io/r/wollmers/Mojolicious-Plugin-DBInfo'><img src='https://coveralls.io/repos/wollmers/Mojolicious-Plugin-DBInfo/badge.svg' alt='Coverage Status' /></a>
<a href='http://cpants.cpanauthors.org/dist/Mojolicious-Plugin-DBInfo'><img src='http://cpants.cpanauthors.org/dist/Mojolicious-Plugin-DBInfo.png' alt='Kwalitee Score' /></a>
<a href="http://badge.fury.io/pl/Mojolicious-Plugin-DBInfo"><img src="https://badge.fury.io/pl/Mojolicious-Plugin-DBInfo.svg" alt="CPAN version" height="18"></a>

=end html

=head1 SYNOPSIS

 $app->plugin('Mojolicious::Plugin::DBInfo');


=head1 DESCRIPTION

L<Mojolicious::Plugin::DBInfo> is a Mojolicious-Plugin.

It creates a route

  /dbinfo

where detailed info is displayed in formatted HTML.

=head2 METHODS

=over 4


=item register

=back

=head1 SEE ALSO

=over

=item *

L<Mojolicious>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/wollmers/Mojolicious-Plugin-DBInfo>

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

@@ dbinfo.css

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

@@ dbinfo.html.ep
<!DOCTYPE html>
<html>
<head>
<title>Database Information</title>
<link media="screen, print, projection" type="text/css" rel="stylesheet" href="/serverinfo.css">
</head>
<body>
<div class="container">

<h1>Database Information</h1>

<h2>Schema sources and classes</h2>

% use Data::Dumper;

% my @sources = schema->sources;
%= tag table => class => "striped" => begin
  %= tag tr => begin
    % for my $header (qw(source table)) {
      %= tag th =>  $header
    % }
  %= end
  % for my $source (sort @sources) {
    % my $table = schema->class($source)->table;
      %= tag tr => begin
        %= tag td =>  $source
        %= tag td =>  $table
      %= end
  % }
%= end

</div>
</body>
</html>

__END__


