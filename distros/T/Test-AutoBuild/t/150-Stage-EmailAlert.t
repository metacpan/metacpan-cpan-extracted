# -*- perl -*-

use Test::More tests => 78;
use warnings;
use strict;
use Log::Log4perl;
use File::Spec::Functions qw(catfile);

Log::Log4perl::init("t/log4perl.conf");

BEGIN {
  use_ok("Test::AutoBuild::Stage::EmailAlert") or die;
  use_ok("Test::AutoBuild::Runtime") or die;
  use_ok("Test::AutoBuild::Module") or die;
  use_ok("Test::AutoBuild::ArchiveManager::Memory") or die;
}

my $counter = MyCounter->new();
$counter->set(2);

my @runtime = (counter => $counter,
	       timestamp => 123);

diag "Test zero";
TEST_ZERO: {
  my $stage = Test::AutoBuild::Stage::EmailAlert->new(name => "send-alerts",
						      label => "Send email alerts",
						      options => {});
  isa_ok($stage, "Test::AutoBuild::Stage::EmailAlert");
}

diag "Global one";
TEST_GLOBAL_ONE: {
  # 1 module, global, single admin, always

  my $mod1 = Test::AutoBuild::Module->new(name => "one", label => "One", sources => {});
  $mod1->_add_result("checkout", "success");
  $mod1->_add_result("build", "success");

  my $arcman = Test::AutoBuild::ArchiveManager::Memory->new();
  my $runtime = Test::AutoBuild::Runtime->new(@runtime,
					      admin_email => "test\@example.com",
					      modules => { "one" => $mod1},
					      arcman => $arcman);

  my $stage = Stub::EmailAlert->new(name => "send-alerts",
				    label => "Send email alerts",
				    options => {
						trigger => "always",
						scope => "global",
						"template-file" => catfile("t", "email.txt"),
					       });
  isa_ok($stage, "Test::AutoBuild::Stage::EmailAlert");

  $stage->prepare();

  $stage->run($runtime);
  ok($stage->succeeded(), "stage succeeeded");
  is($stage->log, undef, "no log generated");

  my @messages = $stage->fetch_messages;

  is($#messages, 0, "one message sent");
  is($messages[0]->[2], "Build Administrator <test\@example.com>", "got message to text\@example.com");
}

diag "Global two";
TEST_GLOBAL_TWO: {
  # 2 module, global, single admin, always

  my $mod1 = Test::AutoBuild::Module->new(name => "one", label => "One", sources => {});
  $mod1->_add_result("checkout", "success");
  $mod1->_add_result("build", "success");

  my $mod2 = Test::AutoBuild::Module->new(name => "two", label => "Two", sources => {});
  $mod2->_add_result("checkout", "success");
  $mod2->_add_result("build", "success");

  my $arcman = Test::AutoBuild::ArchiveManager::Memory->new();
  my $runtime = Test::AutoBuild::Runtime->new(@runtime,
					      admin_email => "test\@example.com",
					      modules => { "one" => $mod1, "two" => $mod2},
					      archive_manager => $arcman);

  my $stage = Stub::EmailAlert->new(name => "send-alerts",
				    label => "Send email alerts",
				    options => {
						trigger => "always",
						scope => "global",
						"template-file" => catfile("t", "email.txt"),
					       });
  isa_ok($stage, "Test::AutoBuild::Stage::EmailAlert");

  $stage->prepare();

  $stage->run($runtime);
  ok($stage->succeeded(), "stage succeeeded");
  is($stage->log, undef, "no log generated");

  my @messages = $stage->fetch_messages;

  is($#messages, 0, "one message sent");
  is($messages[0]->[2], "Build Administrator <test\@example.com>", "got message to text\@example.com");
}

diag "Global three";
TEST_GLOBAL_THREE: {
  # 2 module, global, single admin, fail

  my $mod1 = Test::AutoBuild::Module->new(name => "one", label => "One", sources => {});
  $mod1->_add_result("checkout", "success");
  $mod1->_add_result("build", "success");

  my $mod2 = Test::AutoBuild::Module->new(name => "two", label => "Two", sources => {});
  $mod2->_add_result("checkout", "success");
  $mod2->_add_result("build", "failed");

  my $arcman = Test::AutoBuild::ArchiveManager::Memory->new();
  my $runtime = Test::AutoBuild::Runtime->new(@runtime,
					      admin_email => "test\@example.com",
					      modules => { "one" => $mod1, "two" => $mod2},
					      archive_manager => $arcman);

  my $stage = Stub::EmailAlert->new(name => "send-alerts",
				    label => "Send email alerts",
				    options => {
						trigger => "fail",
						scope => "global",
						"template-file" => catfile("t", "email.txt"),
					       });
  isa_ok($stage, "Test::AutoBuild::Stage::EmailAlert");

  $stage->prepare();

  $stage->run($runtime);
  ok($stage->succeeded(), "stage succeeeded");
  is($stage->log, undef, "no log generated");

  my @messages = $stage->fetch_messages;

  is($#messages, 0, "one message sent");
  is($messages[0]->[2], "Build Administrator <test\@example.com>", "got message to text\@example.com");
}

diag "Global four";
TEST_GLOBAL_FOUR: {
  # 2 module, global, single admin, first-fail, no-cache

  my $mod1 = Test::AutoBuild::Module->new(name => "one", label => "One", sources => {});
  $mod1->_add_result("checkout", "success");
  $mod1->_add_result("build", "success");

  my $mod2 = Test::AutoBuild::Module->new(name => "two", label => "Two", sources => {});
  $mod2->_add_result("checkout", "success");
  $mod2->_add_result("build", "failed");

  my $arcman = Test::AutoBuild::ArchiveManager::Memory->new();
  my $runtime = Test::AutoBuild::Runtime->new(@runtime,
					      admin_email => "test\@example.com",
					      modules => { "one" => $mod1, "two" => $mod2},
					      archive_manager => $arcman);

  my $stage = Stub::EmailAlert->new(name => "send-alerts",
				    label => "Send email alerts",
				    options => {
						trigger => "first-fail",
						scope => "global",
						"template-file" => catfile("t", "email.txt"),
					       });
  isa_ok($stage, "Test::AutoBuild::Stage::EmailAlert");

  $stage->prepare();

  $stage->run($runtime);
  ok($stage->succeeded(), "stage succeeeded");
  is($stage->log, undef, "no log generated");

  my @messages = $stage->fetch_messages;

  is($#messages, 0, "one message sent");
  is($messages[0]->[2], "Build Administrator <test\@example.com>", "got message to text\@example.com");
}

diag "Global five";
TEST_GLOBAL_FIVE: {
  # 2 module, global, single admin, first-fail, same status

  my $mod1 = Test::AutoBuild::Module->new(name => "one", label => "One", sources => {});
  $mod1->_add_result("checkout", "success");
  $mod1->_add_result("build", "success");

  my $mod2 = Test::AutoBuild::Module->new(name => "two", label => "Two", sources => {});
  $mod2->_add_result("checkout", "success");
  $mod2->_add_result("build", "failed");

  my $arcman = Test::AutoBuild::ArchiveManager::Memory->new();
  $arcman->create_archive(1);
  $arcman->create_archive(2);
  $arcman->get_previous_archive()->save_data("one", "build", { status => "success"});
  $arcman->get_previous_archive()->save_data("two", "build", { status => "failed"});
  my $runtime = Test::AutoBuild::Runtime->new(@runtime,
					      admin_email => "test\@example.com",
					      modules => { "one" => $mod1, "two" => $mod2},
					      archive_manager => $arcman);

  my $stage = Stub::EmailAlert->new(name => "send-alerts",
				    label => "Send email alerts",
				    options => {
						trigger => "first-fail",
						scope => "global",
						"template-file" => catfile("t", "email.txt"),
					       });
  isa_ok($stage, "Test::AutoBuild::Stage::EmailAlert");

  $stage->prepare();

  $stage->run($runtime);
  ok($stage->succeeded(), "stage succeeeded");
  is($stage->log, undef, "no log generated");

  my @messages = $stage->fetch_messages;

  is($#messages, -1, "zero message sent");
}

diag "Global six";
TEST_GLOBAL_SIX: {
  # 2 module, global, single admin, fist-fail, different status

  my $mod1 = Test::AutoBuild::Module->new(name => "one", label => "One", sources => {});
  $mod1->_add_result("checkout", "success");
  $mod1->_add_result("build", "success");

  my $mod2 = Test::AutoBuild::Module->new(name => "two", label => "Two", sources => {});
  $mod2->_add_result("checkout", "success");
  $mod2->_add_result("build", "failed");

  my $arcman = Test::AutoBuild::ArchiveManager::Memory->new();
  $arcman->create_archive(1);
  $arcman->create_archive(2);
  $arcman->get_previous_archive()->save_data("one", "build", { status => "success"});
  $arcman->get_previous_archive()->save_data("two", "build", { status => "success"});
  my $runtime = Test::AutoBuild::Runtime->new(@runtime,
					      admin_email => "test\@example.com",
					      modules => { "one" => $mod1, "two" => $mod2},
					      archive_manager => $arcman);

  my $stage = Stub::EmailAlert->new(name => "send-alerts",
				    label => "Send email alerts",
				    options => {
						trigger => "fail",
						scope => "global",
						"template-file" => catfile("t", "email.txt"),
					       });
  isa_ok($stage, "Test::AutoBuild::Stage::EmailAlert");

  $stage->prepare();

  $stage->run($runtime);
  ok($stage->succeeded(), "stage succeeeded");
  is($stage->log, undef, "no log generated");

  my @messages = $stage->fetch_messages;

  is($#messages, 0, "one message sent");
  is($messages[0]->[2], "Build Administrator <test\@example.com>", "got message to text\@example.com");
}

diag "Global seven";
TEST_GLOBAL_SEVEN: {
  # 1 module, global, single admin, always many recipients

  my $mod1 = Test::AutoBuild::Module->new(name => "one", label => "One", sources => {});
  $mod1->_add_result("checkout", "success");
  $mod1->_add_result("build", "success");

  my $arcman = Test::AutoBuild::ArchiveManager::Memory->new();
  my $runtime = Test::AutoBuild::Runtime->new(@runtime,
					      admin_email => "test\@example.com",
					      modules => { "one" => $mod1},
					      arcman => $arcman);

  my $stage = Stub::EmailAlert->new(name => "send-alerts",
				    label => "Send email alerts",
				    options => {
						trigger => "always",
						scope => "global",
						to => "admin, Frank Someone <frank\@example.com>, bob\@noddy.com",
						"template-file" => catfile("t", "email.txt"),
					       });
  isa_ok($stage, "Test::AutoBuild::Stage::EmailAlert");

  $stage->prepare();

  $stage->run($runtime);
  ok($stage->succeeded(), "stage succeeeded");
  is($stage->log, undef, "no log generated");

  my @messages = $stage->fetch_messages;

  is($#messages, 2, "three messages sent");
  is($messages[0]->[2], "Build Administrator <test\@example.com>", "got message to test\@example.com");
  is($messages[1]->[2], "Frank Someone <frank\@example.com>", "got message to frank\@example.com");
  is($messages[2]->[2], "bob\@noddy.com", "got message to bob\@noddy.com");
}

diag "Module one";
TEST_MODULE_ONE: {
  # 1 module, global, developer, always

  my $mod1 = Test::AutoBuild::Module->new(name => "one", label => "One", sources => {},
					  "admin_email" => "joe\@example.com",
					  "admin_name" => "Joe Bloggs");
  $mod1->_add_result("checkout", "success");
  $mod1->_add_result("build", "success");

  my $arcman = Test::AutoBuild::ArchiveManager::Memory->new();
  my $runtime = Test::AutoBuild::Runtime->new(@runtime,
					      admin_email => "test\@example.com",
					      modules => { "one" => $mod1},
					      archive_manager => $arcman);

  my $stage = Stub::EmailAlert->new(name => "send-alerts",
				    label => "Send email alerts",
				    options => {
						trigger => "always",
						scope => "module",
						"template-file" => catfile("t", "email.txt"),
					       });
  isa_ok($stage, "Test::AutoBuild::Stage::EmailAlert");

  $stage->prepare();

  $stage->run($runtime);
  ok($stage->succeeded(), "stage succeeeded");
  is($stage->log, undef, "no log generated");

  my @messages = $stage->fetch_messages;

  is($#messages, 0, "one message sent");
  is($messages[0]->[2], "Joe Bloggs <joe\@example.com>", "got message to joe\@example.com");
}

diag "Module two";
TEST_MODULE_TWO: {
  # 2 module, global, developer, always

  my $mod1 = Test::AutoBuild::Module->new(name => "one", label => "Fred", sources => {},
					  "admin_email" => "joe\@example.com",
					  "admin_name" => "Joe Bloggs");
  $mod1->_add_result("checkout", "success");
  $mod1->_add_result("build", "success");
  my $mod2 = Test::AutoBuild::Module->new(name => "two", label => "Fred", sources => {},
					  "admin_email" => "fred\@example.com",
					  "admin_name" => "Fred Jones");
  $mod2->_add_result("checkout", "success");
  $mod2->_add_result("build", "success");

  my $arcman = Test::AutoBuild::ArchiveManager::Memory->new();
  my $runtime = Test::AutoBuild::Runtime->new(@runtime,
					      admin_email => "test\@example.com",
					      modules => { "one" => $mod1, "two" => $mod2},
					      archive_manager => $arcman);

  my $stage = Stub::EmailAlert->new(name => "send-alerts",
				    label => "Send email alerts",
				    options => {
						trigger => "always",
						scope => "module",
						"template-file" => catfile("t", "email.txt"),
					       });
  isa_ok($stage, "Test::AutoBuild::Stage::EmailAlert");

  $stage->prepare();

  $stage->run($runtime);
  ok($stage->succeeded(), "stage succeeeded");
  is($stage->log, undef, "no log generated");

  my @messages = $stage->fetch_messages;

  is($#messages, 1, "two message sent");
  is($messages[0]->[2], "Joe Bloggs <joe\@example.com>", "got message to joe\@example.com");
  is($messages[1]->[2], "Fred Jones <fred\@example.com>", "got message to fred\@example.com");
}

diag "Module three";
TEST_MODULE_THREE: {
  # 2 module, global, developer, fail

  my $mod1 = Test::AutoBuild::Module->new(name => "one", label => "Fred", sources => {},
					  "admin_email" => "joe\@example.com",
					  "admin_name" => "Joe Bloggs");
  $mod1->_add_result("checkout", "success");
  $mod1->_add_result("build", "success");
  my $mod2 = Test::AutoBuild::Module->new(name => "two", label => "Fred", sources => {},
					  "admin_email" => "fred\@example.com",
					  "admin_name" => "Fred Jones");
  $mod2->_add_result("checkout", "success");
  $mod2->_add_result("build", "failed");

  my $arcman = Test::AutoBuild::ArchiveManager::Memory->new();
  my $runtime = Test::AutoBuild::Runtime->new(@runtime,
					      admin_email => "test\@example.com",
					      modules => { "one" => $mod1, "two" => $mod2},
					      archive_manager => $arcman);

  my $stage = Stub::EmailAlert->new(name => "send-alerts",
				    label => "Send email alerts",
				    options => {
						trigger => "fail",
						scope => "module",
						"template-file" => catfile("t", "email.txt"),
					       });
  isa_ok($stage, "Test::AutoBuild::Stage::EmailAlert");

  $stage->prepare();

  $stage->run($runtime);
  ok($stage->succeeded(), "stage succeeeded");
  is($stage->log, undef, "no log generated");

  my @messages = $stage->fetch_messages;

  is($#messages, 0, "one message sent");
  is($messages[0]->[2], "Fred Jones <fred\@example.com>", "got message to fred\@example.com");
}

diag "Module four";
TEST_MODULE_FOUR: {
  # 2 module, global, developer, first-fail, no cache

  my $mod1 = Test::AutoBuild::Module->new(name => "one", label => "Fred", sources => {},
					  "admin_email" => "joe\@example.com",
					  "admin_name" => "Joe Bloggs");
  $mod1->_add_result("checkout", "success");
  $mod1->_add_result("build", "success");
  my $mod2 = Test::AutoBuild::Module->new(name => "two", label => "Fred", sources => {},
					  "admin_email" => "fred\@example.com",
					  "admin_name" => "Fred Jones");
  $mod2->_add_result("checkout", "success");
  $mod2->_add_result("build", "failed");

  my $arcman = Test::AutoBuild::ArchiveManager::Memory->new();
  my $runtime = Test::AutoBuild::Runtime->new(@runtime,
					      admin_email => "test\@example.com",
					      modules => { "one" => $mod1, "two" => $mod2},
					      archive_manager => $arcman);

  my $stage = Stub::EmailAlert->new(name => "send-alerts",
				    label => "Send email alerts",
				    options => {
						trigger => "fail",
						scope => "module",
						"template-file" => catfile("t", "email.txt"),
					       });
  isa_ok($stage, "Test::AutoBuild::Stage::EmailAlert");

  $stage->prepare();

  $stage->run($runtime);
  ok($stage->succeeded(), "stage succeeeded");
  is($stage->log, undef, "no log generated");

  my @messages = $stage->fetch_messages;

  is($#messages, 0, "one message sent");
  is($messages[0]->[2], "Fred Jones <fred\@example.com>", "got message to fred\@example.com");
}

diag "Module five";
TEST_MODULE_FIVE: {
  # 2 module, global, developer, first-fail, cached-same

  my $mod1 = Test::AutoBuild::Module->new(name => "one", label => "Fred", sources => {},
					  "admin_email" => "joe\@example.com",
					  "admin_name" => "Joe Bloggs");
  $mod1->_add_result("checkout", "success");
  $mod1->_add_result("build", "success");
  my $mod2 = Test::AutoBuild::Module->new(name => "two", label => "Fred", sources => {},
					  "admin_email" => "fred\@example.com",
					  "admin_name" => "Fred Jones");
  $mod2->_add_result("checkout", "success");
  $mod2->_add_result("build", "failed");

  my $arcman = Test::AutoBuild::ArchiveManager::Memory->new();
  $arcman->create_archive(1);
  $arcman->create_archive(2);
  $arcman->get_previous_archive()->save_data("one", "build", { status => "success"});
  $arcman->get_previous_archive()->save_data("two", "build", { status => "failed"});
  my $runtime = Test::AutoBuild::Runtime->new(@runtime,
					      admin_email => "test\@example.com",
					      modules => { "one" => $mod1, "two" => $mod2},
					      archive_manager => $arcman);

  my $stage = Stub::EmailAlert->new(name => "send-alerts",
				    label => "Send email alerts",
				    options => {
						trigger => "first-fail",
						scope => "module",
						"template-file" => catfile("t", "email.txt"),
					       });
  isa_ok($stage, "Test::AutoBuild::Stage::EmailAlert");

  $stage->prepare();

  $stage->run($runtime);
  ok($stage->succeeded(), "stage succeeeded");
  is($stage->log, undef, "no log generated");

  my @messages = $stage->fetch_messages;

  is($#messages, -1, "zero message sent");
}

diag "Module six";
TEST_MODULE_SIX: {
  # 2 module, global, developer, first-fail, cached success

  my $mod1 = Test::AutoBuild::Module->new(name => "one", label => "Fred", sources => {},
					  "admin_email" => "joe\@example.com",
					  "admin_name" => "Joe Bloggs");
  $mod1->_add_result("checkout", "success");
  $mod1->_add_result("build", "success");
  my $mod2 = Test::AutoBuild::Module->new(name => "two", label => "Fred", sources => {},
					  "admin_email" => "fred\@example.com",
					  "admin_name" => "Fred Jones");
  $mod2->_add_result("checkout", "success");
  $mod2->_add_result("build", "failed");

  my $arcman = Test::AutoBuild::ArchiveManager::Memory->new();
  $arcman->create_archive(1);
  $arcman->create_archive(2);
  $arcman->get_previous_archive()->save_data("one", "build", { status => "success"});
  $arcman->get_previous_archive()->save_data("two", "build", { status => "success"});
  my $runtime = Test::AutoBuild::Runtime->new(@runtime,
					      admin_email => "test\@example.com",
					      modules => { "one" => $mod1, "two" => $mod2},
					      archive_manager => $arcman);

  my $stage = Stub::EmailAlert->new(name => "send-alerts",
				    label => "Send email alerts",
				    options => {
						trigger => "first-fail",
						scope => "module",
						"template-file" => catfile("t", "email.txt"),
					       });
  isa_ok($stage, "Test::AutoBuild::Stage::EmailAlert");

  $stage->prepare();

  $stage->run($runtime);
  ok($stage->succeeded(), "stage succeeeded");
  is($stage->log, undef, "no log generated");

  my @messages = $stage->fetch_messages;

  is($#messages, 0, "one message sent");
  is($messages[0]->[2], "Fred Jones <fred\@example.com>", "got message to fred\@example.com");
}

diag "Module seven";
TEST_MODULE_SEVEN: {
  # 1 module, global, many recipients, always

  my $mod1 = Test::AutoBuild::Module->new(name => "one", label => "One", sources => {},
					  "admin_email" => "joe\@example.com",
					  "admin_name" => "Joe Bloggs");
  $mod1->_add_result("checkout", "success");
  $mod1->_add_result("build", "success");

  my $arcman = Test::AutoBuild::ArchiveManager::Memory->new();
  my $runtime = Test::AutoBuild::Runtime->new(@runtime,
					      admin_email => "test\@example.com",
					      modules => { "one" => $mod1},
					      archive_manager => $arcman);

  my $stage = Stub::EmailAlert->new(name => "send-alerts",
				    label => "Send email alerts",
				    options => {
						trigger => "always",
						scope => "module",
						to => "admin, Frank Someone <frank\@example.com>, bob\@noddy.com",
						"template-file" => catfile("t", "email.txt"),
					       });
  isa_ok($stage, "Test::AutoBuild::Stage::EmailAlert");

  $stage->prepare();

  $stage->run($runtime);
  ok($stage->succeeded(), "stage succeeeded");
  is($stage->log, undef, "no log generated");

  my @messages = $stage->fetch_messages;

  is($#messages, 2, "three messages sent");
  is($messages[0]->[2], "Joe Bloggs <joe\@example.com>", "got message to joe\@example.com");
  is($messages[1]->[2], "Frank Someone <frank\@example.com>", "got message to frank\@example.com");
  is($messages[2]->[2], "bob\@noddy.com", "got message to bob\@noddy.com");
}


package Stub::EmailAlert;

use base qw(Test::AutoBuild::Stage::EmailAlert);

sub init {
  my $self = shift;
  $self->SUPER::init(@_);

  $self->{messages} = [];
}

sub fetch_messages {
  my $self = shift;
  return @{$self->{messages}};
}

sub send_message {
  my $self = shift;
  my @params = @_;

  push @{$self->{messages}}, \@params;
}

package MyCounter;

use base qw(Test::AutoBuild::Counter);

sub generate {
    my $self = shift;
    return $self->{value};
}

sub set {
    my $self = shift;
    $self->{value} = shift;
}
