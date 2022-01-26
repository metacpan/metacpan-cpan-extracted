use Module::Build;
use strict;
use warnings;
my $class = Module::Build->subclass(
  class => 'My::Builder',
  code => q{
 use File::Find;
 my $have_p2m = eval "require Pod::Markdown; 1";
 sub ACTION_author_tasks {
   my $self = shift;
   my ($action, $subaction) = @ARGV;
   if ($subaction && ($subaction eq 'readme')) {
     unless ($have_p2m) {
       print "Don't have Pod::Markdown\n";
       return;
     }
     # write POD as <Module>.md in relevant lib/ subdirs
     find (
       sub {
	 return unless $_ =~ /^(.*)\.pm$/;
	 my ($name) = $1;
	 die unless defined $name;
	 my $mdstr = '';
	 my $p2m = Pod::Markdown->new();
	 $p2m->local_module_url_prefix('github::');
	 $p2m->local_module_re(qr/^REST::Neo4p/);
	 $p2m->output_string(\$mdstr);
	 $p2m->parse_file($_);
 	 $mdstr =~ s/%3A%3A/::/g;
	 $mdstr =~ s{(\][(]github::[^)]*[)])}
		    {
		      $_ = $1;
		      s|github::|/lib/|;
		      s|::|/|g;
		      s|[)]$|.md)|;
		      $_
		    }eg;
	 if (length $mdstr > 1) {
	   open my $mdf, '>', "$name.md" or die $!;
	   print $mdf $mdstr;
	   close $mdf;
	 }
       },
       File::Spec->catdir($self->base_dir,'lib')
      );
     
   }
   else {
     print STDERR "Valid author tasks are:\n\treadme\n";
     exit 1;
   }
   # use the dist-version-from .pm's .md as README.md
   if ($self->dist_version_from) {
     my $mdf = $self->dist_version_from;
     $mdf =~ s/\.pm/\.md/;
     $self->copy_if_modified( from => $mdf, to => 'README.md' );
   }
 }

});

my $build =  $class->new
    ( dist_name     => 'REST-Neo4p',
      dist_abstract => 'Perl bindings for a Neo4j graph database',
      dist_version_from => 'lib/REST/Neo4p.pm',
      dist_author => 'Mark A. Jensen',
      license => 'perl',
      requires => {
	'JSON' => 2.0,
	'JSON::XS' => 2.0,
	'JSON::ize' => 0.202,
	'HOP::Stream' => 0,
	'URI::Escape' => 3.3,
	'LWP::UserAgent' => 6.04,
	'LWP::Protocol::https' => 6.06,
	'Exception::Class' => 1.3,
	'Tie::IxHash' => 0,
	'experimental' => 0,
	'MIME::Base64' => 0,
	perl => 5.010001,
	'Neo4j::Driver' => '0.19',
       },
      recommends => {
	'Mojo::UserAgent' => 0,
	'HTTP::Thin' => 0,
       },
      configure_requires => {
	'Module::Build' => 0
       },
      build_requires => {
	'Module::Build' => 0,
	'Test::More' => 0,
	'Test::Exception' => 0,
	'Test::Warn' => 0, 
	'Test::NoWarnings' => 0,
	'Mock::Quick' => 0,
	'List::MoreUtils' => 0,
	'Mojo::Exception' => 0,
	experimental => 0,
	'IPC::Run' => 0,
	'IO::Pty' => 0,

       },
      build_recommends => {
	 'Test::Pod' => 1.0,
	 'Mojo::UserAgent' => 0,
	 'HTTP::Thin' => 0,
	 'Neo4j::Driver' => '0.19',
	},
      meta_merge => {
	resources => {
	  bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=REST-Neo4p',
	  repository  => 'http://github.com/majensen/rest-neo4p.git',
	},
	x_contributors => [
	  'Mark A. Jensen <majensen@cpan.org>',
	  'Arne Johannessen <ajnn@cpan.org>',
	  'Keith Broughton <@keithbro>',
	  'Christiaan Kras <@Htbaa>',
	  'denixx'
	 ]
       },
      perl => 5.010
     );

if ($ENV{REST_NEO4P_BUILD_NONINTERACTIVE}) {
  $build->notes( test_server => $ENV{REST_NEO4P_TEST_SERVER});
  $build->notes( user => $ENV{REST_NEO4P_TEST_USER});
  $build->notes( pass => $ENV{REST_NEO4P_TEST_PASS} );
  $build->notes( agent_mod => $ENV{REST_NEO4P_AGENT_MODULE} );
}
else {
  $build->notes( test_server =>  $build->prompt("Server for live tests:", $ENV{REST_NEO4P_TEST_SERVER} // "http://127.0.0.1:7474"));
  $build->notes( user =>  $build->prompt("Username:", $ENV{REST_NEO4P_TEST_USER} // "") );
  $build->notes( pass =>  $build->prompt("Pass:", $ENV{REST_NEO4P_TEST_PASS} // "") );
  $build->notes( agent_mod => $build->prompt("Agent module:", $ENV{REST_NEO4P_AGENT_MODULE} // "LWP::UserAgent") );
}
$build->create_build_script;

