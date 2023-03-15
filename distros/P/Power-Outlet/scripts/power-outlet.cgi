#!/usr/bin/perl
use strict;
use warnings;
use List::Util qw{first};
use List::MoreUtils qw{uniq};
use CGI qw{};
use CGI::Carp qw{fatalsToBrowser}; #not an exporter
use Config::IniFiles qw{};
use Power::Outlet 0.42 qw{};
use Time::HiRes qw{alarm};
use Parallel::ForkManager 1.01;

my $cgi      = CGI->new;
my $ini      = '/etc/power-outlet.ini';
my $cfg      = Config::IniFiles->new(-file=>$ini);
my $switch   = $cgi->param('switch.x');
my @groups   = uniq map {$cfg->val($_=>'groups', 'Main')} $cfg->Sections;
my $group    = $cgi->param('group') || $groups[0];
my $pm       = Parallel::ForkManager->new(16);

my @outlets  = map {
                 my $section = $_;
                 {
                   section => $section,
                   map {
                        my $key = $_;
                        my @val = $cfg->val($section => $key);
                        @val == 1 ? ($key => $val[0]) : ();
                       } $cfg->Parameters($section)
                 };
               } grep {
                 my $section = $_;
                 first {$_ eq $group} $cfg->val($section=>'groups', 'Main');
               } $cfg->Sections;

if (defined $switch) {
  my $section = $cgi->param('outlet') || ''; #outlet section
  my $data    = first {$_->{'section'} eq $section} @outlets; #this outlet data
  die(qq{Error: Outlet "$section" not found.}) unless defined $data;
  my $action  = $cgi->param('action');
  $action     = 'SWITCH' unless defined $action;
  Power::Outlet->new(%$data)->action($action);
}

my %forms    = ();

$pm->run_on_finish( #register before main forking loop
  sub {
    my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data) = @_;
    my $section      = $data->{'section'};
    my $form         = $data->{'form'};
    $forms{$section} = $form;
  }
);

foreach my $outlet (@outlets) {#main forking loop
  $pm->start and next; #child fork for each outlet
  my $Power_Outlet = Power::Outlet->new(%$outlet);
  local $@;
  my $status = eval{
                    local $SIG{ALRM} = sub {die "timeout\n"};
                    alarm 2.05; #some devices are slow to warmup
                    my $return       = $Power_Outlet->query;
                    alarm 0;
                    $return;
                   } || 'ERROR';
  my $error  = $@;
  print STDERR $error;
  $status    = 'TIMEOUT' if $error =~ m/timeout/;
  my $image  = $status eq 'TIMEOUT' ? '/power-outlet-images/btn-timeout.png'
             : $status eq 'ON'      ? '/power-outlet-images/btn-on.png'
             : $status eq 'OFF'     ? '/power-outlet-images/btn-off.png'
             :                        '/power-outlet-images/btn-error.png';
  my $action = $status eq 'ON'      ? 'OFF'
             : $status eq 'OFF'     ? 'ON'
             : 'SWITCH';
  #form for each outlet
  my $form   = $cgi->div({-style=>'width: 119px; padding-bottom: 109px; position: relative; float: left;'},
                 $cgi->div({-style=>'background-color: #FFFFFF; position: absolute; left: 1px; right: 1px; top: 1px; bottom: 1px; padding: 1px; border: 1px solid; border-color: #D9D9D9; border-radius: 25px;'},
                   $cgi->p({-align=>'center', -width=>'100%'}, $Power_Outlet->name),
                   $cgi->p({-align=>'center', -width=>'100%'},
                     $cgi->start_multipart_form(#-style=>"display: inline; margin: 0px 0px 0px 0px; padding: 0px 0px 0px 0px;",
                                                -method=>'POST',
                                                -action=>$cgi->script_name),
                     $cgi->hidden(-name => 'group'),
                     $cgi->hidden(-name => 'action', -value=>$action,              -override=>1),
                     $cgi->hidden(-name => 'outlet', -value=>$outlet->{'section'}, -override=>1),
                     $cgi->image_button(-name=>'switch',  -src=>$image),
                     $cgi->end_multipart_form,
                   ),
                 ),
               );
  #data to return to parent process
  $pm->finish(0 => {section=>$outlet->{'section'}, form=>$form});
}

$pm->wait_all_children; #back to parent

my @forms    = map {$forms{$_->{'section'}}} @outlets; #ordered per ini
my $title    = 'Power::Outlet Controller';
print $cgi->header(-type=>'text/html', -charset=>'utf-8'),
      $cgi->start_html({
                        -title   => $title,
                        -bgcolor => '#C3CAD2',
                        -meta    => {viewport=>'initial-scale = 1.0, maximum-scale = 1.0'}, #for iPhone
                       }),
      $cgi->title($title),
      $cgi->h1($cgi->a({-href=>$cgi->script_name, -style=>'text-decoration: none; color: black;'}, $title)),
      (@groups > 1 ? $cgi->p(join(', ', map {$cgi->a({-href=>"?group=$_"}, $_)} @groups)) : ()),
      $cgi->div({-style=>'overflow: hidden; width: 100%'}, @forms),
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
  groups=Inside
  groups=Kitchen

If you need to override the defaults

  [Unique_Section_Name]
  type=iBoot
  host=Lamp
  port=80
  pass=PASS
  name=My iBoot Description
  groups=Outside
  groups=Deck

WeMo device

  [WeMo]
  type=WeMo
  host=mywemo
  groups=Inside
  groups=Study

Default Location: /usr/share/power-outlet/conf/power-outlet.ini

=head1 BUILD

  rpmbuild -ta Power-Outlet-*.tar.gz

=head1 INSTALLATION

I recommend installation with the provided RPM package perl-Power-Outlet-application-cgi which installs to /usr/share/power-outlet and configures Apache with /etc/httpd/conf.d/power-outlet.conf.

  sudo yum install perl-Power-Outlet-application-cgi

=cut
