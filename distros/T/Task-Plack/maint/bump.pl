use lib 'lib';
use Task::Plack;
use FileHandle;

open my $out, ">", "cpanfile" or die $!;
Task::Plack->cpanfile($out);
