################################################################################
NOTE: PLEASE CONSIDER THIS AN ALPHA RELEASE!!

I have been playing with this idea for a couple of months now, and am ready to
incorporate feedback from the wider community.

If you can help with any of the following it would be greatly appreciated:

* use it in your own tests - if you have any questions about it, or feel I've
  missed anything in the documentation, please let me know.

* recommendations for other modules that would benefit from being mocked via
  this framework. I'm particulary looking for modules where there has been
  significant changes to the interface over major versions where there is a
  case where people have kept the of version because refactoring their code
  to use a more modern version is impractical.

* peer review of the approach - I am not a low level programmer. I muddled my
  way through overriding require with a lot of help from LLMs. Although I have
  tested what I have implemented, I'm worried I might have missed something.

I would love to hear from you: clive.holloway@gmail.com

################################################################################

This code allows you to easily mock pretty much any perl code for unit tests in
a simple way with a plugin architecture.

It also has mocks for DBI and LWP::UserAgent code, and can be extended to mock other code
as needed.

Browse the tests and POD for more information.


How to use it
=============

To be able to unit test, your code must be written so that it can be mocked.

Older codebases will probably need refactoring to allow for this. Here's
a simple example:

    # original code
    package MyModule;
    sub process_user {
        my $uid = shift;

        # do something with the uid (validation etc)

        open my $fh, '<', "/home/$uid/data.txt" or die "Cannot open file: $!";
        my $data = <$fh>;
        close $fh;

        # do something with $data
    }

As it stands, this code cannot easily be mocked because it directly opens a file
in the middle of the sub.

By refactoring the file read into a separate sub that can be mocked, we can make
it testable:

    # refactored code
    package MyModule;
    sub _get_user_data {
        my $uid = shift;

        open my $fh, '<', "/home/$uid/data.txt" or die "Cannot open file: $!";
        my $data = <$fh>;
        close $fh;

        return $data;
    }
    sub process_user {
        my $uid = shift;

        # do something with the uid (validation etc)

        my $data = _get_user_data($uid);

        # do something with $data
    }

Now, we can mock the `_get_user_data` sub in our tests:

    use TestModule;
    use SimpleMock qw(register_mocks);

    register_mocks(
        SUBS => {
            MyModule => {
                _get_user_data => [
                    { args => [1] , returns => 'mocked data for user 1' },
                    { returns => 'default mocked data for all other user IDs' },
                ],
            },
        },
    );

If you are being systematic, you can set default mocks in SimpleMocks::Mocks::MyModule
for _get_user_data, reducing the number of times you need to specify the mock in
your tests.

The example above is not indicative of a best practice - it's just a simple
example to illustrate the point.

If you are not prepared to clean up the organization of your code, you will
not be able to use this framework effectively. The more you can refactor your code
to allow for simple mocking, the easier it will be to test it.
