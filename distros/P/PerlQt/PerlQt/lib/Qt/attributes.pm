package Qt::attributes;
#
# I plan to support public/protected/private attributes. here goes.
# Attributes default to protected.
#
# package MyBase;
# use Qt::attributes qw(
# private:
#    foo
# protected:
#    bar
# public:
#    baz
# );
#
# package MyDerived;
# use Qt::isa qw(MyBase);
#
# sub foo {
#     # 1 way to access private attributes from derived class
#     #
#     # this->{$class} contains private attributes for $class
#     # I specify it to always work that way,
#     # so feel free to use it in code.
#     this->{MyBase}{foo} = 10;
#
#     # 2 ways to access protected attributes
#     bar = 10;
#     this->{bar} = 10;
#
#     # 3 ways to access public attributes
#     baz = 10;
#     this->{baz} = 10;
#     this->baz = 10;
# }
#
# Attributes override any method with the same name, so you may want
# to prefix them with _ to prevent conflicts.
#
sub import {
    my $class = shift;
    my $caller = (caller)[0];

    for my $attribute (@_) {
	exists ${ ${$caller . '::META'}{'attributes'} }{$attribute} and next;
	Qt::_internal::installattribute($caller, $attribute);
        ${ ${$caller . '::META'}{'attributes'} }{$attribute} = 1;
    }
}

1;
