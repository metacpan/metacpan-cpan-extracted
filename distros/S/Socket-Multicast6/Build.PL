use Module::Build;

my $class = Module::Build->subclass(
  code => q{
    use Devel::PPPort;
    use ExtUtils::Constant;

    sub ACTION_build {
        my $self = shift;
        $self->depends_on('ppport_h','constants');
        $self->SUPER::ACTION_build;
    }

    sub ACTION_ppport_h {
        my $self = shift;
        my $filepath = 'lib/Socket/ppport.h';
        unless (-e $filepath) {
            print "Writing $filepath\n";
            Devel::PPPort::WriteFile($filepath);
        }
        $self->add_to_cleanup($filepath);
    }

    sub ACTION_constants {
        my $self = shift;
        my $c_file_path = 'lib/Socket/const-c.inc';
        my $xs_file_path = 'lib/Socket/const-xs.inc';
        unless (-e $c_file_path && -e $xs_file_path) {
            print "Writing $c_file_path and $xs_file_path\n";
            ExtUtils::Constant::WriteConstants(
                NAME => 'Socket::Multicast6',
                NAMES => [qw(
                    IP_MULTICAST_IF
                    IP_MULTICAST_TTL
                    IP_MULTICAST_LOOP
                    IP_ADD_MEMBERSHIP
                    IP_DROP_MEMBERSHIP
                    IP_ADD_SOURCE_MEMBERSHIP
                    IP_DROP_SOURCE_MEMBERSHIP
                    IPV6_MULTICAST_IF
                    IPV6_MULTICAST_HOPS
                    IPV6_MULTICAST_LOOP
                    IPV6_JOIN_GROUP
                    IPV6_LEAVE_GROUP
                    MCAST_JOIN_GROUP
                    MCAST_BLOCK_SOURCE
                    MCAST_UNBLOCK_SOURCE
                    MCAST_LEAVE_GROUP
                    MCAST_JOIN_SOURCE_GROUP
                    MCAST_LEAVE_SOURCE_GROUP
                )],
                C_FILE => $c_file_path,
                XS_FILE => $xs_file_path
            );
        }
        $self->add_to_cleanup($c_file_path);
        $self->add_to_cleanup($xs_file_path);
    }
  },
);

my $build = $class->new
(
    module_name => 'Socket::Multicast6',
    license => 'perl',
    build_requires => {
      'Module::Build' 	=> '0.20',
      'ExtUtils::Constant' => 0,
      'ExtUtils::CBuilder' => 0,
      'Devel::PPPort' => 0,
    },
    requires => {
      'perl'			=> '5.6.1',
      'Socket'		=> 0,
      'Test::More'		=> 0,
      'Socket'		=> 0,
      'Socket6'		=> 0.19,
    }
);

$build->create_build_script;
