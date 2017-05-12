# Developer tests require:
#   Test::More
#   Test::BDD::Cucumber
our $RunDeveloperTests = 0;

# Default config. 
# If you're a developer of Net::LDAPapi or are likely to have multiple trees that share common test config,
# then you should override in ~/.net-ldapapi-test-config.conf (See below)
our %TestConfig = (
  'ldap' => {
    'server' => {
      'tcp' => {
        '-host' => 'localhost',
        '-port' => 389,
      },
      'ldapi' => {
        '-url' => 'ldapi:///',
        '-debug' => 1
      }
    },
    'base_dn' => 'dc=example,dc=com',
    'bind_types' => {
      'anonymous' => {
        'enabled' => 1,
      },
      'simple' => {
        'enabled' => 1,
        'bind_dn' => 'cn=admin,dc=example,dc=com',
        'bind_pw' => 'password',
      },
      'sasl' => {
        'enabled' => 1,
        'sasl_parms' => {
          '-mech' => 'EXTERNAL',
        },
        'identity' => "gidNumber=" . $< . "+uidNumber=" . (split(/ /, "$("))[0] . ",cn=peercred,cn=external,cn=auth"
      }
    },
    'default_server' => 'tcp',
    'default_bind_type' => 'simple',
  },
  'search' => {
     'filter' => "sn=Last",
     'count' => 1,
  },
  'data' => {
    'test_container_attributes' => {
      'objectClass' => ['top', 'organizationalUnit'],
      'ou' => 'Test Container',
    },
    'container_attributes' => {
      'objectClass' => ['top', 'organizationalUnit'],
      'ou' => 'Test - Add Container',
    },
    'entry_attributes' => {
      'objectClass' => ['top', 'person' ,'organizationalPerson', 'inetOrgPerson'],
      'cn' => 'Test - Add Entry',
      'sn' => 'Entry',
      'givenName' => 'Test - Add',
    },
    'test_container_dn' => 'ou=Test Container',
    'container_dn' => 'ou=Test - Add Container',
    'entry_dn' => 'cn=Test - Add Entry',
  },
  'rename' => {
    'dn' => 'cn=Test - Add Entry',
    'new_rdn' => 'cn=Test - Add Entry',
    'new_super' => 'ou=Test - Add Container'
  },
  'modify' => {
    'new_attribute' => {
      'title' => { 'a' => ['New Test Title'] }
    },
    'modify_attribute' => {
      'title' => { 'r' => ['Modified Test Title'] }
    },
    'remove_attribute' => {
      'title' => ''
    },
  },
  'syncrepl' => {
    'enabled' => 1,
    'cookie_dir' => '/tmp/'  
  },
  'server_controls' => {
    'sss' => [
      {
        'attributeType' => 'sn', 
        'orderingRule' => '2.5.13.3', 
        'reverseOrder' => 1
      },
    ],
    'vlv' => {
      'beforeCount' => 0,
      'afterCount' => 3,
      'target' => {
        'byOffset' => {
          'offset' => 1,
          'contentCount' => 0
        }
      }
    },
  },
  'compare' => {
    'entry_attribute' => 'cn', 
    'compare_attribute' => 'ou'  
  }
);


# Allow overrides from outside the source tree.
# This is a standard Perl file. Example below.
if ( -e $ENV{'HOME'} . '/.net-ldapapi-test-config.conf') {
  require $ENV{'HOME'} . '/.net-ldapapi-test-config.conf';
}

1;
__END__

$RunDeveloperTests = 1;

$TestConfig{'ldap'}{'base_dn'} = "o=Test Data,c=NZ";
$TestConfig{'ldap'}{'bind_types'}{'simple'}{'bind_dn'} = "cn=admin,o=Test Data,c=NZ";
$TestConfig{'ldap'}{'bind_types'}{'simple'}{'bind_pw'} = "password";

$TestConfig{'search'}{'filter'} = "sn=O'Donnell";


1;
