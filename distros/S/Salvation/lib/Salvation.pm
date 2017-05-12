use strict;

package Salvation;

our $VERSION = '0.9913'; $VERSION = eval( $VERSION );

-1;

# ABSTRACT: Simple and free architectural solution for huge applications

=pod

=head1 NAME

Salvation - Simple and free architectural solution for huge applications

=head1 DESCRIPTION

=head2 What is it?

Salvation is a little framework which by itself does almost nothing.

In example, it does not:

=over

=item manage interactions with a web-server;

=item manage threads or forks of a daemon process;

=item hide database interactions.

=back

Salvation is some kind of human supervisor. It forces developer to:

=over

=item use OOP;

=item write modular applications splitting the code into many different packages and subroutines, and do it from the beginning;

=item use strategy pattern;

=item use MVC pattern when you need to render textual data;

=back

Salvation also provides transparent mechanism to load strategies and substitute parts of algorithm. And it suppresses most of the exceptions from being C<die>d with, giving you control over those via hooks definable inside of L<Salvation::System>.

=head2 When should it be used?

Salvation is not suitable for small projects like marketing promo-actions of type "give me some promo-code and I'll give you a discount or a free product", or blogs, or dumb web-crawlers, or alike.

Salvation is best used for building huge, complex systems: CRMs or other sales leads' management systems, in example.

=head2 How to use it?

The best learning is practice, so let's look at the example.

The task is to create an abstract user request management system web application. Let's give this system a name - C<URMS>.

C<URMS> will, among other needs, need to display some web page with the request's user data, request's data and management controls. All these things will be tied to some request object which is needed to be created somehow. So C<URMS> will have four services:

=over

=item RequestInfoWindow

To gather and form request's data.

=item UserInfoWindow

To gather and form request's user data.

=item RequestMgmtControls

To form request management controls.

=item RequestLoader

To load request.

=back

Let's create a new project files and directory tree with L<Salvation::CLI>.

 $ salvation.pl -d -S URMS -s RequestInfoWindow,UserInfoWindow,RequestMgmtControls,RequestLoader

Following files will be created:

 ./URMS.pm
 URMS/Services/RequestInfoWindow.pm
 URMS/Services/RequestInfoWindow/Defaults/M.pm
 URMS/Services/RequestInfoWindow/Defaults/V.pm
 URMS/Services/RequestInfoWindow/Defaults/C.pm
 URMS/Services/RequestInfoWindow/Defaults/OutputProcessor.pm
 URMS/Services/RequestInfoWindow/DataSet.pm
 URMS/Services/UserInfoWindow.pm
 URMS/Services/UserInfoWindow/Defaults/M.pm
 URMS/Services/UserInfoWindow/Defaults/V.pm
 URMS/Services/UserInfoWindow/Defaults/C.pm
 URMS/Services/UserInfoWindow/Defaults/OutputProcessor.pm
 URMS/Services/UserInfoWindow/DataSet.pm
 URMS/Services/RequestMgmtControls.pm
 URMS/Services/RequestMgmtControls/Defaults/M.pm
 URMS/Services/RequestMgmtControls/Defaults/V.pm
 URMS/Services/RequestMgmtControls/Defaults/C.pm
 URMS/Services/RequestMgmtControls/Defaults/OutputProcessor.pm
 URMS/Services/RequestMgmtControls/DataSet.pm
 URMS/Services/RequestLoader.pm
 URMS/Services/RequestLoader/Defaults/M.pm
 URMS/Services/RequestLoader/Defaults/V.pm
 URMS/Services/RequestLoader/Defaults/C.pm
 URMS/Services/RequestLoader/Defaults/OutputProcessor.pm
 URMS/Services/RequestLoader/DataSet.pm

Let's edit C<URMS> package, which is the definition of our system, and a subclass of L<Salvation::System>.

C<URMS> needs to define services it has.

Let's add the following code:

 sub BUILD
 {
 	my $self = shift;

	my $constraint = sub
	{
		return $self -> request_page_constraint();
	};

	$self -> Service( $_, { constraint => $constraint } )
		for
			'RequestLoader', # order matters; mind to put your loaders first
			'RequestInfoWindow',
			'UserInfoWindow',
			'RequestMgmtControls'
	;

	return;
 }

 sub request_id
 {
 	my $self = shift;

	return $self -> args() -> { 'request_id' };
 }

 sub request_page_constraint
 {
 	my $self = shift;

	return defined $self -> request_id();
 }

This will tell the system that when it has C<request_id> argument - it should load and run four services: C<RequestInfoWindow>, C<UserInfoWindow>, C<RequestMgmtControls>, C<RequestLoader>.

Let's then look at the C<URMS::Services::RequestLoader::DataSet> package. Semantics tells us that this module should be responsible for loading the request object. The class it defines is a subclass of L<Salvation::Service::DataSet>. We need to edit its C<main> method so it will return some object. For the sake of example, let it be simple HashRef.

 sub main
 {
 	my $self = shift;

 	my $object = {
		id => 42,
		title => 'The Question',
		product => 100500, # magic number irrelevant to example
		serial_number => 'QWER-TYUI-OPAS', # magic string irrelevant to example
		type => 1, # magic number representing type of request
		comment => 'Why I even bought your product?'
	};

 	return [
		( $self -> service() -> system() -> request_id() == $object -> { 'id' } ? (
			$object
		) : () )
	];
 }

The only purpose of C<RequestLoader> service is to load request and make it accessible to other services. So let's edit C<URMS::Services::RequestLoader> package, which is a service definition and a subclass of L<Salvation::Service>, and add following code which will make our request object easily accessible:

 sub main
 {
 	my $self = shift;

	$self -> system() -> storage() -> put( request => $self -> dataset() -> first() );

	return;
 }

The code above stores the first row returned by DataSet into system's shared storage (see L<Salvation::SharedStorage> man page) for key C<request>.

We can now delete following files as we won't need them:

 URMS/Services/RequestLoader/Defaults/M.pm
 URMS/Services/RequestLoader/Defaults/V.pm
 URMS/Services/RequestLoader/Defaults/C.pm
 URMS/Services/RequestLoader/Defaults/OutputProcessor.pm

We need to form request data for further displaying now.

Let's edit C<URMS::Services::RequestInfoWindow::DataSet> package now. It should return request object to C<URMS::Services::RequestInfoWindow> service so it will be able to process request object. So we will change C<URMS::Services::RequestInfoWindow::DataSet::main> to something like this:

 sub main
 {
 	my $self = shift;

	my $object = $self -> service() -> system() -> storage() -> get( 'request' );

	return [
		( defined( $object ) ? $object : () )
	];
 }

Now we should write a template so the service will know what data should be gathered. To do this, we will edit C<URMS::Services::RequestInfoWindow::Defaults::V> package which is the definition of view and a subclass of L<Salvation::Service::View>. We will modify its C<main> to return template, as it is the fastest way:

 sub main
 {
 	return [
		raw => [
			'id',
			'serial_number',
			'title',
			'comment'
		],
		custom => [
			'type'
		]
	];
 }

See L<Salvation::Service::View> man page for more information about templates.

The next step is to write a model so the service will know how to process each specified column. Let's edit C<URMS::Services::RequestInfoWindow::Defaults::M> package. It is a model definition and a subclass of L<Salvation::Service::Model>. We will add following code so the model will be able to process columns of type C<raw>:

 sub __raw
 {
 	my ( $self, $object, $column ) = @_;

	return $object -> { $column };
 }

We will also add following code to be able to process column with name C<type> of type C<custom>:

 sub custom_type
 {
 	my ( $self, $object ) = @_;

	my %table = (
		1 => 'regular',
		2 => 'specific'
	);

	return $table{ $object -> { 'type' } };
 }

Okay! So now is the time to check the thing out. We will do it using this simple script named C<test.pl>:

 #!/usr/bin/perl

 use strict;

 package test;

 use URMS ();

 print URMS
 	-> new(
		args => {
			request_id => 42
		}
	)
	-> start()
 , "\n";

 exit 0;

Running this script, you will see output like this:

 <?xml version="1.0" encoding="UTF-8"?>
 <output>
    <data>
        <stack></stack>
    </data>
    <data>
        <stack>
            <list name="raw">
                <frame title="[FIELD_ID]" name="id" type="raw"><![CDATA[42]]></frame>
                <frame title="[FIELD_SERIAL_NUMBER]" name="serial_number" type="raw"><![CDATA[QWER-TYUI-OPAS]]></frame>
                <frame title="[FIELD_TITLE]" name="title" type="raw"><![CDATA[The Question]]></frame>
                <frame title="[FIELD_COMMENT]" name="comment" type="raw"><![CDATA[Why I even bought your product?]]></frame>
            </list>
            <list name="custom">
                <frame title="[FIELD_TYPE]" name="type" type="custom"><![CDATA[regular]]></frame>
            </list>
        </stack>
    </data>
    <data>
        <stack></stack>
    </data>
    <data>
        <stack></stack>
    </data>
 </output>

And then, just to demonstrate how the hooks (implementation of strategy pattern) work, we will change how the request's serial_number column should be rendered. Let's imagine that the requests of type C<1> will be processed only by employees of your company, but requests of type C<2> will be processed by you partners and because of some major issues you can't show a serial_number to them. If it sounds like "oh, I should go and write some C<if...else> clause" - it sounds like a crutch. To avoid crutches, we will use strategy pattern. We will create a hook for type C<type> and value C<2> via L<Salvation::CLI>:

 salvation.pl -d -S URMS -s RequestInfoWindow -h Type -v 2

This will create following files:

 URMS/Services/RequestInfoWindow/Hooks/Type/2.pm
 URMS/Services/RequestInfoWindow/Hooks/Type/2/Defaults/M.pm
 URMS/Services/RequestInfoWindow/Hooks/Type/2/Defaults/V.pm
 URMS/Services/RequestInfoWindow/Hooks/Type/2/Defaults/C.pm
 URMS/Services/RequestInfoWindow/Hooks/Type/2/Defaults/OutputProcessor.pm

Let's remove the ones we won't use in this example, leaving only model and hook definition:

 URMS/Services/RequestInfoWindow/Hooks/Type/2/Defaults/V.pm
 URMS/Services/RequestInfoWindow/Hooks/Type/2/Defaults/C.pm
 URMS/Services/RequestInfoWindow/Hooks/Type/2/Defaults/OutputProcessor.pm

Then let's edit hook's model, C<URMS::Services::RequestInfoWindow::Hooks::Type::2::Defaults::M>, adding following code:

 sub raw_serial_number
 {
 	my ( $self, $object ) = @_;

	my $serial_number = $object -> { 'serial_number' };

	$serial_number =~ s/^(..).+?(..)$/${1}XX-XXXX-XX${2}/;

	return $serial_number;
 }

Also we need to change class's ancestor of C<URMS::Services::RequestInfoWindow::Hooks::Type::2::Defaults::M> from L<Salvation::Service::Model> to C<URMS::Services::RequestInfoWindow::Defaults::M>:

 extends 'URMS::Services::RequestInfoWindow::Defaults::M';

Then let's change type of object returned by C<URMS::Services::RequestLoader::DataSet> from C<1> to C<2>, so it will return following object:

 my $object = {
 	id => 42,
	title => 'The Question',
	product => 100500,
	serial_number => 'QWER-TYUI-OPAS',
	type => 2, # Here is the change
	comment => 'Why I even bought your product?'
 };

Then we should register a hook inside of service, editing C<URMS::Services::RequestLoader>, adding following code:

 sub BUILD
 {
 	my $self = shift;

	$self -> Hook( [ $self -> dataset() -> first() -> { 'type' }, 'Type' ] );

	return;
 }

And then let's run C<test.pl> again, so it will produce an output kind of like the following:

 <?xml version="1.0" encoding="UTF-8"?>
 <output>
    <data>
        <stack>
            <list name="raw">
                <frame title="[FIELD_ID]" name="id" type="raw"><![CDATA[42]]></frame>
                <frame title="[FIELD_SERIAL_NUMBER]" name="serial_number" type="raw"><![CDATA[QWXX-XXXX-XXAS]]></frame>
                <frame title="[FIELD_TITLE]" name="title" type="raw"><![CDATA[The Question]]></frame>
                <frame title="[FIELD_COMMENT]" name="comment" type="raw"><![CDATA[Why I even bought your product?]]></frame>
            </list>
            <list name="custom">
                <frame title="[FIELD_TYPE]" name="type" type="custom"><![CDATA[specific]]></frame>
            </list>
        </stack>
    </data>
    <data>
        <stack></stack>
    </data>
    <data>
        <stack></stack>
    </data>
 </output>

As you can see, hook has changed the way C<serial_number> column is rendered. So hooks can be used to change behaviour of your service and its components like view, model, contoller and OutputProcessor.

You can continue playing with example files to test things as you like, simultaneously reading the docs for appropriate base classes and other modules.

=cut

