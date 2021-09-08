#! /usr/bin/env perl
use Test2::V0;
use Mock::Data;

my @tests= (
	{
		name => 'Plain set of generators',
		args => [ generators => { a => [42] } ],
		check => object {
			call generators => {
				a => object { call items => [42]; }
			};
		}
	},
	{
		name => 'Relative package name plugin',
		args => [['MyPlugin']],
		check => object {
			call generators => {
				a => object { call items => [40]; }
			};
		}
	},
	{
		name => 'Scoped package name plugin',
		args => [ plugins => ['My::Plugin2'] ],
		check => object {
			call generators => {
				'My::Plugin2::a' => object { call items => [60]; },
				a => object { call items => [60]; },
			};
		}
	},
	{
		name => 'Plugin and literal generator override',
		args => [ plugins => ['My::Plugin2'], generators => { a => [22], b => [55] } ],
		check => object {
			call generators => {
				'My::Plugin2::a' => object { call items => [60]; },
				a => object { call items => [22]; },
				b => object { call items => [55]; },
			};
		}
	},
	{
		name => 'Plugin merge',
		args => [[qw/ MyPlugin My::Plugin2 /]],
		check => object {
			call generators => {
				'My::Plugin2::a' => object { call items => [60]; },
				a => object { call items => [40,60]; },
			};
		}
	},
	{
		name => 'Plugin no merge in reverse order',
		args => [[qw/ My::Plugin2 MyPlugin /]],
		check => object {
			call generators => {
				'My::Plugin2::a' => object { call items => [60]; },
				a => object { call items => [40]; },
			};
		}
	}
);

for (@tests) {
	my $mockdata= Mock::Data->new(@{ $_->{args} });
	is( $mockdata, $_->{check}, $_->{name} );
}

{
	package Mock::Data::Plugin::MyPlugin;
	sub apply_mockdata_plugin {
		my ($class, $mockdata)= @_;
		$mockdata->add_generators(
			a => [ 40 ],
		);
	}
}
{
	package MyPlugin;
	sub apply_mockdata_plugin {
		my ($class, $mockdata)= @_;
		$mockdata->add_generators(
			a => [ 50 ],
		);
	}
}
{
	package Mock::Data::Plugin::My::Plugin2;
	sub apply_mockdata_plugin {
		my ($class, $mockdata)= @_;
		$mockdata->combine_generators(
			'My::Plugin2::a' => [ 60 ],
		);
	}
}

done_testing;
