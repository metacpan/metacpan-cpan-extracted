#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
require Perl::Dist::WiX::Fragment::StartMenu;
require Perl::Dist::WiX::DirectoryTree;

BEGIN {
	if ( $^O eq 'MSWin32' ) {
#		plan tests => 10;
		plan skip_all => 'This test needs fixed.';
	} else {
		plan skip_all => 'Not on Win32';
	}
}

my $tree = Perl::Dist::WiX::DirectoryTree->new(
	app_dir  => 'C:\\Test',
	app_name => 'Test',
);

$tree->initialize_tree('589', 32, 3);

my $menu_1 = Perl::Dist::WiX::Fragment::StartMenu->new(
    directory_id => 'ProgramMenuFolder',
);

ok( defined $menu_1, 'creating a P::D::W::Fragment::StartMenu' );

isa_ok( $menu_1, 'Perl::Dist::WiX::Fragment::StartMenu', 'The start menu');
isa_ok( $menu_1, 'WiX3::XML::Fragment', 'The start menu');

my $empty_fragment = <<'END_OF_STRING';
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_StartMenuIcons'>

  </Fragment>
</Wix>
END_OF_STRING

is( $menu_1->as_string(), $empty_fragment, 'StartMenu->as_string() with no component');

eval {
	my $component_1 = $menu_1->add_shortcut(
		id          => 'Test_Icon',
		name        => 'Test Icon',
		description => 'Test Icon Entry',
		target      => '[D_TestDir]file.test',
		working_dir => 'TestDir',
		icon_id     => 'icon.test',
	);
};

ok( q{} eq $@, 'Adding a shortcut' );

eval {
    my $component_3 = $menu_1->add_shortcut(
        sitename    => 'ttt.test.invalid',
        id          => undef,
        name        => 'Test Icon',
        description => 'Test Icon Entry',
        target      => '[D_TestDir]file.test',
        working_dir => 'TestDir',
        menudir_id  => 'D_App_Menu',
        icon_id     => 'icon.test',
        trace       => 100,
    );
};

like($@, qr(invalid: id), 'StartMenu->add_component() catches bad id' );

eval {
    my $component_4 = $menu_1->add_shortcut(
        sitename    => 'ttt.test.invalid',
        id          => 'Test_Icon',
        name        => undef,
        description => 'Test Icon Entry',
        target      => '[D_TestDir]file.test',
        working_dir => 'TestDir',
        menudir_id  => 'D_App_Menu',
        icon_id     => 'icon.test',
        trace       => 100,
    );
};

like($@, qr(invalid: name), 'StartMenu->add_component() catches bad name' );

eval {
    my $component_5 = $menu_1->add_shortcut(
        sitename    => 'ttt.test.invalid',
        id          => 'Test_Icon',
        name        => 'Test Icon',
        description => 'Test Icon Entry',
        target      => undef,
        working_dir => 'TestDir',
        menudir_id  => 'D_App_Menu',
        icon_id     => 'icon.test',
        trace       => 100,
    );
};

like($@, qr(invalid: target), 'StartMenu->add_component() catches bad target' );

eval {
    my $component_6 = $menu_1->add_shortcut(
        sitename    => 'ttt.test.invalid',
        id          => 'Test_Icon',
        name        => 'Test Icon',
        description => 'Test Icon Entry',
        target      => '[D_TestDir]file.test',
        working_dir => undef,
        menudir_id  => 'D_App_Menu',
        icon_id     => 'icon.test',
        trace       => 100,
    );
};

like($@, qr(invalid: working_dir), 'StartMenu->add_component() catches bad working_dir' );

my $menu_test_string_1 = <<'EOF';
<?xml version='1.0' encoding='windows-1252'?>
<Wix xmlns='http://schemas.microsoft.com/wix/2006/wi'>
  <Fragment Id='Fr_StartMenuIcons'>
    <DirectoryRef Id='D_App_Menu'>
      <Component Id='C_RF_App_Menu' Guid='0F339262-C340-3016-8F44-9045A9FC5835'>
        <RemoveFolder Id='RF_App_Menu' On='uninstall' />
      </Component>
      <Component Id='C_S_Test_Icon' Guid='E43BA3C7-0EB3-32FA-801D-7824A63B5E51'>
        <Shortcut Id='S_Test_Icon' Description='Test Icon Entry' Icon='I_icon.test' Name='Test Icon' Target='[D_TestDir]file.test' WorkingDirectory='D_TestDir' />
        <CreateFolder Directory='D_App_Menu' />
      </Component>
    </DirectoryRef>
  </Fragment>
</Wix>
EOF

is( $menu_1->as_string(), $menu_test_string_1, 'StartMenu->as_string()');
