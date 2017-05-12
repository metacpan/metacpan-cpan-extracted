use strict;
use warnings;

use Test::More tests => 13;
use Test::Mock::LWP;

use_ok('Net::Lighthouse');
can_ok( 'Net::Lighthouse', 'new' );
my $lh = Net::Lighthouse->new( account => 'sunnavy' );
isa_ok( $lh, 'Net::Lighthouse::Base' );
for my $method (qw/project token user/) {
    can_ok( $lh, $method );
    isa_ok( $lh->$method, 'Net::Lighthouse::' . ucfirst $method );
}

can_ok( $lh, 'projects' );
$Mock_ua->mock( get            => sub { $Mock_response } );
$Mock_ua->mock( default_header => sub { } );                  # to erase warning
$Mock_response->mock(
    content => sub {
        local $/;
        open my $fh, '<', 't/data/projects.xml' or die $!;
        <$fh>;
    }
);

my @projects = $lh->projects;
is( scalar @projects, 2, 'found projects' );
isa_ok( $projects[0], 'Net::Lighthouse::Project' );
is( $projects[0]->id, 35918, 'project id' );
