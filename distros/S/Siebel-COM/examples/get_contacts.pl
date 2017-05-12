use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Siebel::COM::App::DataServer;

my $help = 0;
my $man  = 0;

my ( $user, $password, $cfg, $datasource );

GetOptions(
    'user=s'       => \$user,
    'password=s'   => \$password,
    'help|?'       => \$help,
    'cfg=s'        => \$cfg,
    'datasource=s' => \$datasource,
    'man|?'        => \$man
) or pod2usage(2);
pod2usage(1) if $help;

pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

pod2usage(2)
  unless ( ( defined($user) )
    and ( defined($password) )
    and ( defined($cfg) )
    and ( defined($datasource) ) );

my $schema = {
    'Contact' => [
        'Birth Date',
        'Created',
        'Created By Name',
        'Email Address',
        'Fax Phone #',
        'First Name',
        'Id',
        'Job Title',
        'Last Name',
        'Updated',
        'Updated By Name',
        'Work Phone #'
    ]
};

my $sa;

eval {

    $sa = Siebel::COM::App::DataServer->new(
        {
            cfg         => $cfg,
            data_source => $datasource,
            user        => $user,
            password    => $password
        }
    );

    my ( $bo, $bc, $key, $field, $moreResults );

    $sa->login();

    foreach $key ( keys(%$schema) ) {

        $bo = $sa->get_bus_object($key);
        $bc = $bo->get_bus_comp($key);

        foreach $field ( @{ $schema->{$key} } ) {

            $bc->activate_field($field);

        }

        $bc->clear_query();
        $bc->query();
        $moreResults = $bc->first_record();

        while ($moreResults) {

            printf("-----\n");

            foreach $field ( @{ $schema->{$key} } ) {

                printf( "%40s: %s\n", $field, $bc->get_field_value($field) );

            }

            $moreResults = $bc->next_record();
        }
    }

};

if ($@) {

    warn $@;
    Siebel::COM::App::DataServer->get_app_error($sa);

}

__END__

=pod

=head1 NAME

get contact data from a Siebel database by using COM

=head1 SYNOPSIS

get_contacts.pl --user=foobar --password=foobar --cfg=foobar.cfg --datasource=foobar [--help] [--man]

Options:

    --help          this brief help message
    
    --man           full description of the script

    --user          user for connection authentication

    --password      password for to authentication

    --cfg           Siebel client configuration file

    --datasource    the datasource inside the configuration file to be used

=head1 DESCRIPTION

This is a simple example of usage of L<Siebel::COM>.

This script will connect to a Siebel database by using COM (more specifically Siebel COM data server) and loop over all contacts in the database, printing to the
STDOUT the following information:

=over

=item *

Birth Date

=item *

Created

=item *

Created By Name

=item *

Email Address

=item *

Fax Phone

=item *

First Name

=item *

Id

=item *

Job Title

=item *

Last Name

=item *

Updated

=item *

Updated By Name

=item *

Work Phone

=back

=cut
