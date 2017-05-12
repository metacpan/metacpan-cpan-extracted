package PEF::Front::Guide::QuickStart;

1;

__END__

=encoding utf8
 
=head1 NAME
 
PEF::Front::Guide::QuickStart - a quick-start guide to the 
PEF::Front web framework.

=head1 DESCRIPTION

A quick-start guide with examples to get you up and running with the 
PEF::Front web framework.

=head1 PREPARATION

There're many possible ways to start your L<PSGI> application. 
You can choose any that you like. Here is one of the most effective
possible way.

  nginx -> uwsgi -> PEF::Front(application)

L<Nginx|https://www.nginx.com/> accepts incoming requests and serves
static content. Some defined request it passes to L<uwsgi|https://uwsgi-docs.readthedocs.io/en/latest/PSGIquickstart.html>.
Which works as a very effective PSGI-server and passes semi-prepared requests
to L<PEF::Front> framework. Which runs your application on.

=head2 Approximate B<Nginx> configuration

This is usually in C</etc/nginx/sites-enabled/> directory. 
Alternatively you can put this (say, app-nginx.conf) configuration 
file in any directory you like and add 
C<include /$FULL_PATH_TO/app-nginx.conf> to your nginx.conf file 
in C<http> section.

  server {
    listen 80 default_server;

    root /$PROJECT_DIR/www-static;
    access_log /$PROJECT_DIR/log/nginx.access.log;
    error_log /$PROJECT_DIR/log/nginx.error.log;
    client_max_body_size 100m;
    server_name $PROJECT.DOMAIN;
    # Static content
    location =/favicon.ico {}
    location /jss/ {}
    location /fonts/ {}
    location /images/ {}
    location /styles/ {}
    location /captchas/ {}
    # Dynamic content
    location / {
      include uwsgi_params;
      uwsgi_pass unix:///run/uwsgi/app/$UWSGI_APP/socket;
      uwsgi_modifier1 5;
    }
    location ~ /\. {
      deny all;
    }
  }

=head2 Approximate B<uwsgi> configuration

  /etc/uwsgi/apps-available/$UWSGI_APP.ini
  /etc/uwsgi/apps-enabled/$UWSGI_APP.ini is symbolic link 
   to /etc/uwsgi/apps-available/$UWSGI_APP.ini
   
  [uwsgi]
  plugins = psgi,logfile
  chdir = /$PROJECT_DIR
  logger = file:log/application.log
  psgi = bin/startup.pl
  master = true
  processes = 10
  stats = 127.0.0.1:5000
  perl-no-plack = true
  #cheaper-algo = spare
  #cheaper = 3
  #cheaper-initial = 6
  #cheaper-step = 1
  harakiri = 0
  uid = $PROJECT_USER
  gid = www-data
  chmod-socket = 664

=head2 Typical project structure

  cd $PROJECT_DIR
  mkdir  app bin log model templates var www-static
  mkdir app/$MyAPP
  cd app/$MyAPP
  mkdir InFilter Local OutFilter
  cd var
  mkdir cache captcha-db tt_cache upload
  cd ../ www-static
  mkdir captchas images jss styles
  
Now you are ready to start coding your application.

=head1 CONFIGURING

=head2 AppFrontConfig

Edit C</$PROJECT_DIR/app/$MyAPP/AppFrontConfig.pm>. Usually you need only 
something like this:

  package $MyAPP::AppFrontConfig;
  sub cfg_db_user      { $DBUSER }
  sub cfg_db_password  { $DBPASSWORD }
  sub cfg_db_name      { $DBNAME }
  1;

When you don't need multilanguage support, then add

  sub cfg_no_nls { 1 }
  sub cfg_no_multilang_support { 1 }

More info about configuration is L<here|PEF::Front::Config>.

=head2 startup.pl

Typical startup file

  #!/usr/bin/perl

  use lib qw'/$PROJECT_DIR/app';

  use $MyAPP::AppFrontConfig;
  use PEF::Front::Preload;

  use PEF::Front::Route (
    '/'               => ['/index' 'R'],
    qr'/index(.*)'    => '/appIndex$1',
  );

  PEF::Front::Route->to_app();

L<PEF::Front::Preload> makes database connect and builds validation
subroutines for model method descriptions. It's very often needed to
make route for '/' path but after that it's up to whether to use 
default routing scheme or amend it. See L<PEF::Front::Route> for
more info about routing.

=head1 APPLICATION

"Local" model handlers are located in C</$PROJECT_DIR/app/$MyAPP/Local>.
For example, C</$PROJECT_DIR/app/$MyAPP/Local/Article.pm>:


  package MyApp::Local::Article;
  use DBIx::Struct qw(connector hash_ref_slice);
  use strict;
  use warnings;

  sub get_articles {
    my ($req, $context) = @_;
    my $articles = all_rows(
        [   "article a" => -join => "author w",
            -columns => ['a.*', 'w.name author']
        ],
        -order_by => {-desc => 'id_article'},
        -limit    => $req->{limit},
        -offset   => $req->{offset},
        sub { $_->filter_timestamp->data }
    );
    for my $article (@$articles) {
        $article->{comment_count} =
          one_row([comment => -columns => 'count(*)'], {hash_ref_slice $article, 'id_article'})->count;
    }
    return {
        result   => "OK",
        articles => $articles,
        count    => one_row([article => -columns => 'count(*)'])->count
    };
  }

Model description for this handler C</$PROJECT_DIR/model/GetArticles.yaml>:

  ---
  params:
    limit:
      regex: ^\d+$        
      max-size: 3
    offset:
      regex: ^\d+$
      max-size: 10
  model: Article::get_articles

Then this handler can be called from AJAX with request like:

  GET /ajaxGetArticles?limit=5&offset=0

or from template:

  [% articles="get articles".model(limit => 5, offset => 0) %]


=head1 AUTHOR
 
This module was written and is maintained by Anton Petrusevich.

=head1 Copyright and License
 
Copyright (c) 2016 Anton Petrusevich. Some Rights Reserved.
 
This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
