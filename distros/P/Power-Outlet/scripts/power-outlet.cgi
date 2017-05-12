#!/usr/bin/perl
use strict;
use warnings;
use List::Util qw{first};
use CGI qw{};
use CGI::Carp qw{fatalsToBrowser}; #not an exporter
use Config::IniFiles qw{};
use Power::Outlet qw{};

my $cgi      = CGI->new;
my $ini      = "../conf/power-outlet.ini";
my $cfg      = Config::IniFiles->new(-file=>$ini);

my $switch   = $cgi->param("switch.x");
my @outlets  = map {
                 my $section=$_;
                 {
                   section => $section,
                   map {
                        my $key=$_;
                        $key => $cfg->val($section=>$key);
                       } $cfg->Parameters($section)
                 };
               } $cfg->Sections;

if (defined $switch) {
  my $section= $cgi->param("outlet") || ""; #outlet section
  my $data   = first {$_->{"section"} eq $section} @outlets; #this outlet data
  die(qq{Error: Outlet "$section" not found.}) unless defined $data;
  Power::Outlet->new(%$data)->switch;
}

my @forms    = ();
foreach my $data (@outlets) {
  my $outlet = Power::Outlet->new(%$data);
  my $status = eval{$outlet->query} || "NO ACCESS";
  my $image  = $status eq "ON" ? "/power-outlet-images/btn-on.png" : "/power-outlet-images/btn-off.png";
  #Generate a form for each outlet
  push @forms, $cgi->div({-style=>"width: 119px; padding-bottom: 109px; position: relative; float: left;"},
                 $cgi->div({-style=>"background-color: #FFFFFF; position: absolute; left: 1px; right: 1px; top: 1px; bottom: 1px; padding: 1px; border: 1px solid; border-color: #D9D9D9; border-radius: 25px;"},
                   $cgi->p({-align=>"center", -width=>"100%"}, $outlet->name),
                   $cgi->p({-align=>"center", -width=>"100%"},
                     $cgi->start_multipart_form(#-style=>"display: inline; margin: 0px 0px 0px 0px; padding: 0px 0px 0px 0px;",
                                                -method=>"POST",
                                                -action=>$cgi->script_name),
                     $cgi->hidden(-name => "outlet", -value=>$data->{"section"}, -override=>1),
                     $cgi->image_button(-name=>'switch',  -src=>$image),
                     $cgi->end_multipart_form,
                   ),
                 ),
               );
}

my $title    = 'Power::Outlet Controller';
print $cgi->header(-type=>'text/html', -charset=>'utf-8'),
      $cgi->start_html({
                        -title=>$title,
                        -bgcolor=>"#C3CAD2",
                        -meta=>{viewport=>"initial-scale = 1.0, maximum-scale = 1.0"}, #for iPhone
                       }),
      $cgi->title($title),
      $cgi->h1($cgi->a({-href=>$cgi->script_name, -style=>"text-decoration: none; color: black;"}, $title)),
      $cgi->div({-style=>"overflow: hidden; width: 100%"}, @forms),
      $cgi->end_html,
      "\n";


__END__

=head1 NAME

power-outlet.cgi - Control multiple Power::Outlet devices from web browser

=head1 DESCRIPTION

power-outlet.cgi is a CGI application to control multiple Power::Outlet devices.  It was written to work on iPhone and look ok in most browsers.

=head1 CONFIGURATION

To add an outlet for the CGI application, add a new INI section to the power-outlet.ini file.

  [Unique_Section_Name]
  type=iBoot
  host=Lamp

If you need to override the defaults

  [Unique_Section_Name]
  type=iBoot
  host=Lamp
  port=80
  pass=PASS
  name=My iBoot Description

WeMo device

  [WeMo]
  type=WeMo
  host=mywemo

Default Location: /usr/share/power-outlet/conf/power-outlet.ini

=head1 INSTALLATION

I recomend installation with the provided RPM package perl-Power-Outlet-application-cgi which installs to /usr/share/power-outlet and configures Apache with /etc/httpd/conf.d/power-outlet.conf.

=cut
