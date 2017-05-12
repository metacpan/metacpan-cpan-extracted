use ExtUtils::MakeMaker;

eval { require Time::HiRes; };

if ($@) {
    warn <<EOT;

******************************************************
It looks like you\'re missing Time::HiRes. This module
can work fine without it, but having it reduces the
amount of collisions when storing files into a queue,
so it is a good idea to install it before going any
further.
******************************************************


EOT
    ;
}

WriteMakefile(
    'NAME'		=> 'Queue::Dir',
    'VERSION_FROM'	=> 'Dir.pm', # finds $VERSION
    'PREREQ_PM'		=> 
	      {
		  'Sys::Hostname' => 0,
		  'Params::Validate' => 0,
		  'Test::More' => 0,
		  'File::Spec' => 0,
		  'File::Path' => 0,
	      }, # e.g., Module::Name => 1.1
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM	=> 'Dir.pm',
		AUTHOR     	=> 'Luis E. Muñoz <luismunoz@cpan.org>') : ()),
);
