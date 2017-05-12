#!/usr/bin/perl -w
use Project::Gantt;
use Project::Gantt::Skin;

    my $skin = new Project::Gantt::Skin (
        doTitle     => 0,
        primaryFill => '#EEEEE0',
        font        => '/Library/Fonts/Vera.ttf' );

    my $chart = new Project::Gantt (
        file        => "test.png",
        skin        => $skin,
        mode        => 'months',
        description => 'All Sub Projects' );

    my $resource = $chart->addResource(name=>'_');

    my $p1 = $chart->addSubProject (
        description => 'Overall'
        );
my $res2 = $p1->addResource(name=>'_');

    $p1->addTask (
        description => 'Proj A',
        resource    => $resource,
        start       => '2005-02-01',
        end         => '2005-03-15' 
        );

    my $p2 = $p1->addSubProject (
        description => 'Proj B'
        );

    $p2->addTask (
        description => 'Proj B1',
        resource    => $res2,
        start       => '2005-04-01',
        end         => '2005-05-15' 
        );

    $p2->addTask (
        description => 'Proj B2',
        resource    => $res2,
        start       => '2005-05-01',
        end         => '2005-06-15'
        );

    $chart->display ();
