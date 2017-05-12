=head1 Name

QBit::Class - base class for QBit framework.

=head1 Description

All classes must inherit L<QBit::Class>.

=cut

package QBit::Class;
$QBit::Class::VERSION = '0.3';
use qbit;

=head1 Methods

=head2 new

B<Arguments:>

=over

=item

B<%fields> - fields to store in object.

=back

B<Return value:> blessed object.

=cut

sub new {
    my ($class, %fields) = @_;

    $class = ref($class) || $class;

    my $self = \%fields;
    bless($self, $class);

    $self->init();

    return $self;
}

=head2 init

B<No arguments.>

Method called from L</new> before return object.

=cut

sub init { }

=head2 mk_accessors

B<Arguments:>

=over

=item

B<@fields> - array of strings, names of accessors.

=back

It generate read/write accessors.

 __PACKAGE__->mk_accessors(qw(fieldname fieldname2));
 ....
 $self->fieldname(); # return value
 $self->fieldname('newval'); # set value

=cut

sub mk_accessors {
    my ($self, @fields) = @_;

    my $class = ref($self) || $self;

    no strict 'refs';
    foreach my $field (@fields) {
        *{"${class}::$field"} = $self->_rw_accessor($field);
    }
}

=head2 mk_ro_accessors

B<Arguments:>

=over

=item

B<@fields> - array of strings, names of accessors.

=back

It generate only read accessors.

 __PACKAGE__->mk_accessors(qw(fieldname fieldname2));
 ....
 $self->fieldname(); # return value

=cut

sub mk_ro_accessors {
    my ($self, @fields) = @_;

    my $class = ref($self) || $self;

    no strict 'refs';
    foreach my $field (@fields) {
        *{"${class}::$field"} = $self->_ro_accessor($field);
    }
}

=head2 abstract_methods

B<Arguments:>

=over

=item

B<@metods> - array of strings, names of abstract methods.

=back

 __PACKAGE__->abstract_methods(qw(method1 method2));
 ....
 $self->method1(); # trow exception with text "Abstract method: method1" if descendant has not override it.

=cut

sub abstract_methods {
    my ($package, @metods) = @_;

    {
        no strict 'refs';
        *{"${package}::$_"} = eval('sub {$package->__abstract__(\'' . $_ . '\')}') foreach @metods;
    }
}

sub _rw_accessor {
    my ($class, $field) = @_;

    return sub {@_ > 1 ? $_[0]->{$field} = $_[1] : $_[0]->{$field}};
}

sub _ro_accessor {
    my ($self, $field) = @_;

    return sub {$_[0]->{$field}};
}

sub __abstract__ {
    my ($class, $method) = @_;

    throw gettext("Abstract method: %s", $method);
}

TRUE;