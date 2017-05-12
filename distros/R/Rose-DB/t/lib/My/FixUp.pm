package My::FixUp;

sub fixup
{
  My::DB->modify_db(domain => 'otherdomain',
                    type   => 'othertype',
                    port   => 456);
}

My::DB->modify_db(domain => 'otherdomain',
                  type   => 'othertype',
                  port   => 789);

1;
