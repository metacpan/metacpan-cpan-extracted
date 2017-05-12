package QBit::Base;
$QBit::Base::VERSION = '0.002';
use qbit;

if ($] < 5.008) {
    *_module_to_filename = sub {
        (my $fn = $_[0]) =~ s!::!/!g;
        $fn .= '.pm';
        return $fn;
      }
} else {
    *_module_to_filename = sub {
        (my $fn = $_[0]) =~ s!::!/!g;
        $fn .= '.pm';
        utf8::encode($fn);
        return $fn;
      }
}

sub import {
    my ($class, @packages) = @_;

    my $package_heir = caller(0);

    my $stash = package_stash($package_heir);

    my @bases;
    foreach my $package (@packages) {
        if ($package_heir eq $package) {
            throw gettext('Class "%s" tried to inherit from itself', $package_heir);
        }

        next if grep $_->isa($package), ($package_heir, @bases);

        my $fn = _module_to_filename($package);
        require $fn;

        push @bases, $package;

        my $ip_stash = package_stash($package);

        foreach my $meta (keys(%$ip_stash)) {
            if (exists($stash->{$meta})) {
                if (ref($stash->{$meta}) eq 'HASH') {
                    $stash->{$meta} = clone({%{$ip_stash->{$meta}}, %{$stash->{$meta}}});
                }
            } else {
                $stash->{$meta} = clone($ip_stash->{$meta});
            }
        }
    }

    require QBit::Application::Model::DBManager;

    {
        no strict 'refs';
        push @{"$package_heir\::ISA"}, @bases;

        *{"${package_heir}::model_fields"} = sub {
            my ($class, %fields) = @_;

            my $stash = package_stash($package_heir);

            QBit::Application::Model::DBManager::model_fields($package_heir, %{$stash->{'__MODEL_FIELDS__'}}, %fields);
        };

        *{"${package_heir}::model_filter"} = sub {
            my ($class, %filter) = @_;

            my $stash = package_stash($package_heir);

            my %filter_def = (
                db_accessor => $filter{'db_accessor'} // $stash->{'__DB_FILTER_DBACCESSOR__'},
                fields => {%{$stash->{'__DB_FILTER__'}}, %{$filter{'fields'}}},
            );

            QBit::Application::Model::DBManager::model_filter($package_heir, %filter_def);
        };
    }
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::Base - inheritance pattern.

it's do not working with multistate_graph

=head1 GitHub

https://github.com/QBitFramework/QBit-Base

=head1 Install

=over

=item *

cpanm QBit::Base

=item *

apt-get install libqbit-base-perl (http://perlhub.ru/)

=back

B<Example:>

    package MyPackage::Users;

    use qbit;

    use QBit::Base qw(QBit::Application::Model::DBManager::Users);

    __PACKAGE_->model_fields(
        full_name => {
            label      => d_gettext('Full name'),
            depends_on => [qw(name midname surname)],
            get        => sub {
                return join(' ', grep {$_} map {$_[1]->{$_}} qw(surname name midname));
              }
        },
        phone => {
            label      => d_gettext('Phone'),
            depends_on => ['extra_fields'],
            get        => sub {
                $_[1]->{'extra_fields'}{'phone'}[0];
              }
        },
    );

    __PACKAGE__->model_filter(
        db_accessor => 'db',
        fields      => {
            phone => {
                type     => 'extra_fields',
                field    => 'id',
                fk_field => 'user_id',
                table    => 'users_extra_fields'
            },
        },
    );

    TRUE;

=cut
