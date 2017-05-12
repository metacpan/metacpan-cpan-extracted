package Puzzle;

our $VERSION = '0.21';

use base 'Puzzle::Core';

sub instance {
	return $Puzzle::Core::instance;
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Puzzle - A Web framework 

=head1 SYNOPSIS

In httpd.conf or virtual host configuration file

  <IfModule mod_perl.c>
    AddType text/html .mpl
    PerlSetVar ServerName "myservername"
    <FilesMatch "\.mpl$">
      SetHandler  perl-script
      PerlHandler Puzzle::MasonHandler
    </FilesMatch>
    <LocationMatch "(\.mplcom|handler|\.htt|\.yaml)$|autohandler">
      Order deny,allow 
      Deny from All
    </LocationMatch>
  </IfModule>

in your document root, a config.yaml like this

  frames:           0
  base:              ~
  frame_bottom_file: ~
  frame_left_file:   ~
  frame_right_file:  ~
  frame_top_file:    ~
  # you MUST CHANGE auth component because this is a trivial auth controller
  # auth_class:   "Puzzle::Session::Auth"
  # auth_class:   "YourNameSpace::Auth"
  gids:
                - everybody
  login:        /login.mpl
  namespace:    cov
  description:  ""
  keywords:     ""
  debug:        1
  cache:        0
  db:
    enabled:                1
    persistent_connection:  0
    username:               your_username
    password:               your_password
    host:                   your_hosts
    name:                   your_db_name
    session_table:          sysSessions
  #traslation:
  #it:           "YourNameSpace::Lang::it"
  #default:      it
  #mail:
  #  server:       "your.mail.server"
  #  from:         "your@email-address"

in your document root, a Mason autohandler file like this

  <%once>
    use Puzzle;
    use abc;
  </%once>
  <%init>
    $abc::puzzle ||= new Puzzle(cfg_path => $m->interp->comp_root
	  .  '/config.yaml';
    $abc::dbh = $abc::puzzle->dbh;
    $abc::puzzle->process_request;
  </%init>

an abc module in your @ISA path

  package abc;

  our $puzzle;
  our $dbh;

  1;



=head1 DESCRIPTION

Puzzle is a web framework based on HTML::Mason, HTML::Template::Pro with
direct support to dabatase connection via DBIx::Class. It include a
template system, a session user tracking and a simple authentication and
authorization login access for users with groups and privileges.

=head1 SEE ALSO

For update information and more help about this framework take a look to:

http://code.google.com/p/puzzle-cpan/

=head1 AUTHOR

Emiliano Bruni, E<lt>info@ebruni.it<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Emiliano Bruni

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
