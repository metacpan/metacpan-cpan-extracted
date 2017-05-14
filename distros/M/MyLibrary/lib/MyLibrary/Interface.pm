package MyLibrary::Interface;

use Template qw( :template );

sub output_interface {
        my $self = $_[0];
        my $html = $self->{html};
        my $options = {};
        foreach my $attr (keys %{$self}) {
                if ($attr ne 'html') {
                        $options->{$attr} = $self->{$attr};
                }
        }
        my $interface = Template->new({
                TRIM => 1,
                PRE_CHOMP  => 1,
                POST_CHOMP => 0
        });

        $interface->process(\$html, $options) || die $interface->error();

} # end sub output_interface

sub get_interface {
        my $dbh = MyLibrary::DB->dbh();
        my $class = shift;
        my %opts = @_;
        my $q = qq(SELECT * FROM interface WHERE name='$opts{name}');
        my $interface = $dbh->selectrow_hashref($q);
        my @arr = split(/,\W+/, $interface->{options});
        my @opts;
        foreach my $pair (@arr) {
                push @opts, split / => /, $pair;
        }
        my %interface_opts = (@opts);
        my $self = {
                html => $interface->{'html'},
                %interface_opts,
                %opts
        };
        return bless $self, $class;
} # end sub build_interface

1;
