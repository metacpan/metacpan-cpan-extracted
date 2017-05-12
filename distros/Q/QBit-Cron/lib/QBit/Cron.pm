package QBit::Cron;
$QBit::Cron::VERSION = '0.004';
use qbit;

use Fcntl qw(:flock);

sub check_rights {1}    # Cron has full privileges

sub get_cron_methods {
    my ($self) = @_;

    my $methods = {};

    package_merge_isa_data(
        ref($self),
        $methods,
        sub {
            my ($package, $res) = @_;

            my $pkg_methods = package_stash($package)->{'__CRON__'} || {};
            foreach my $path (keys(%$pkg_methods)) {
                foreach my $method (keys(%{$pkg_methods->{$path}})) {
                    $methods->{$path}{$method} = $pkg_methods->{$path}{$method};
                }
            }
        },
        __PACKAGE__
    );

    return $methods;
}

sub do {
    my ($self, $path, $method) = @_;

    ($path, $method) = @ARGV unless defined($method);

    throw gettext("Expecting 'path'")   unless defined $path;
    throw gettext("Expecting 'method'") unless defined $method;

    $self->pre_run();

    # assume internal user (id = 0)
    $self->set_option('cur_user', {id => 0});

    my $methods = $self->get_cron_methods();

    throw gettext('Method "%s" with path "%s" does not exists', $method, $path)
      unless exists($methods->{$path}{$method});

    my $cron = $methods->{$path}{$method}{'package'}->new(app => $self);
    my $attrs = $methods->{$path}{$method}{'attrs'};

    my $lock_name;
    $lock_name = defined($attrs->{'lock'}) ? $attrs->{'lock'} : "cron__${path}__$method"
      if exists($attrs->{'lock'});

    if (defined($lock_name)) {
        unless ($self->get_lock($lock_name)) {
            l gettext("Other %s->%s is running now, I'm exiting", $path, $method) unless $attrs->{'silent'};
            return;
        }
    }

    try {
        $methods->{$path}{$method}{'sub'}($cron);
    }
    catch {
        $self->release_lock($lock_name) if defined($lock_name);
        throw $_[0];
    };

    $self->release_lock($lock_name) if defined($lock_name);

    $self->post_run();
}

sub generate_crond {
    my ($self, %opts) = @_;

    my $cron_pkg = ref($self);

    my $methods = $self->get_cron_methods();

    print "MAILTO=\"$opts{'mail_to'}\"\n" if exists($opts{'mail_to'});
    print "CONTENT_TYPE=\"text/plain; charset=utf-8\"\n";
    print "\n";

    my $cron_cmd = 'perl'
      . (exists($opts{'framework_path'})   ? " -I$opts{'framework_path'}"   : '')
      . (exists($opts{'application_path'}) ? " -I$opts{'application_path'}" : '')
      . " -M$cron_pkg -e'$cron_pkg->new->do'";

    my ($cur_user) = getpwuid($<);
    my $user = $opts{'user'} || $cur_user;
    foreach my $path (sort keys(%$methods)) {
        foreach my $method (sort keys(%{$methods->{$path}})) {
            print join("\t", $methods->{$path}{$method}{'time'}, $user, "$cron_cmd $path $method") . "\n\n";
        }
    }
}

sub get_lock {
    my ($self, $name) = @_;

    $self->{'__LOCKS__'}{$name}{'file'} = "/tmp/${>}_${name}.lock";

    open($self->{'__LOCKS__'}{$name}{'fh'}, '>', $self->{'__LOCKS__'}{$name}{'file'})
      || throw gettext('Cannot create lock file "%s"', $self->{'__LOCKS__'}{$name}{'file'});

    return flock($self->{'__LOCKS__'}{$name}{'fh'}, LOCK_EX | LOCK_NB);
}

sub release_lock {
    my ($self, $name) = @_;

    return unless exists($self->{'__LOCKS__'}{$name});

    flock($self->{'__LOCKS__'}{$name}{'fh'}, LOCK_UN);
    close($self->{'__LOCKS__'}{$name}{'fh'});
    unlink($self->{'__LOCKS__'}{$name}{'file'});
    delete($self->{'__LOCKS__'}{$name});

    return TRUE;
}

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::Cron - Class for working with Cron.

=head1 GitHub

https://github.com/QBitFramework/QBit-Cron

=head1 Install

=over

=item *

cpanm QBit::Cron

=item *

apt-get install libqbit-cron-perl (http://perlhub.ru/)

=back

For more information. please, see code.

=cut
