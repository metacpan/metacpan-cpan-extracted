package Role {
    use Moo::Role;
    sub foo { print "Role\n" }
}

package Parent {
    use Moo;
    with 'Role';
    before 'foo' => sub { print "Parent\n" };
}

package Child {
    use Moo;
    extends 'Parent';
    with 'Role';
    before 'foo' => sub { print "Child\n" };
}

Child->new->foo;
