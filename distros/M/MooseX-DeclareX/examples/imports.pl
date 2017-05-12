use 5.010;
use MooseX::DeclareX
	imports => [
		'MooseX::ClassAttribute',
		'Path::Class' => [qw( file dir )],
		'CLASS',
	];

class Local::System
{
	class_has temp_dir => (
		is  => read_write,
		isa => 'Path::Class::Entity',
	);
	
	CLASS->temp_dir( dir "/tmp" );
}

say for sort Local::System->temp_dir->children;

