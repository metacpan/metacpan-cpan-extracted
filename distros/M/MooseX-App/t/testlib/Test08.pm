package Test08;
use MooseX::App::Simple qw(MutexGroup Depends);
use Moose::Util::TypeConstraints;

option 'FileFormat' => (
   is  => 'ro',
   isa => enum([qw(csv tsv xml)]),
);

option 'WriteToFile' => (
   is         => 'ro',
   isa        => 'Bool',
   mutexgroup => 'FileOp',
   depends    => [qw(FileFormat)],
);

option 'ReadFromFile' => (
   is         => 'ro',
   isa        => 'Bool',
   mutexgroup => 'FileOp',
   depends    => [qw(FileFormat)],
);

has 'private_option' => (
   is      => 'ro',
   isa     => 'Int',
   default => 0,
);

1;
