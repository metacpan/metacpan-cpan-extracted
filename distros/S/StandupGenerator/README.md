# Standup Generator

*An easy way to create .txt files to keep track of your daily standups for team meetings*

**Contents**
1. [Description](https://github.com/jtreeves/standup-generator#description)
2. [Inspiration](https://github.com/jtreeves/standup-generator#inspiration)
3. [Requirements](https://github.com/jtreeves/standup-generator#requirements)
4. [Installation](https://github.com/jtreeves/standup-generator#installation)
5. [Features](https://github.com/jtreeves/standup-generator#features)
6. [Usage](https://github.com/jtreeves/standup-generator#usage)
7. [Code Examples](https://github.com/jtreeves/standup-generator#code-examples)
8. [Testing](https://github.com/jtreeves/standup-generator#testing)
9. [Future Goals](https://github.com/jtreeves/standup-generator#future-goals)

## Description

Standup Generator is a module for creating and editing standup files. It is a **Perl** package for use on a **MacOS** computer via a CLI configured to work with either zsh or bash. It contains three main methods: one for creating a new standup *.txt* file, based on whatever the previous standup file contained; another for opening standup files in your default text editor; and a final one for viewing all the standup files from the past week. It also includes a helper method that you can execute via the CLI to update your config files with shortcuts to enable you to execute those main methods with less typing on your end. To learn more about how to use the package, visit its barebones [documentation](https://metacpan.org/dist/StandupGenerator) on **CPAN**.

## Inspiration

I like to type out my standups before delivering them in my team's daily morning meetings. Otherwise, I'll just end up rambling, and I'll often forget to include an important element. After creating basic *.txt* files for my standups over the course of a few weeks, I found that the files turned into ad hoc to-do lists that helped me stay on track with my work. However, creating those files from scratch every day was inefficient, so I came up with some bash scripts to streamline the process. As always, I soon realized that I could still factor out more inefficiencies. At that point, I decided to switch to a more robust scripting language that I could use to create a package that I could publish in case other people wanted to use my same shortcuts. I started playing around with Perl, and this package is the result. While it's only in a rudimentary stage and could still be improved upon (see [Future Goals](https://github.com/jtreeves/standup-generator#future-goals) below), I think it's adequate for basic usage.

## Requirements

- MacOS
- Perl 5
- CLI configured to work with either zsh or bash

## Installation

### Download Package

#### Set Up Environment

Use `perlbrew` to bypass many of the default administrative restrictions in MacOS. Check out its [site](https://perlbrew.pl) to learn more about that tool. Here are the basic steps for installing and configuring `perlbrew`:

1. Run `\curl -L https://install.perlbrew.pl | bash` in your CLI
2. Add `source ~/perl5/perlbrew/etc/bashrc` to your `.zshrc` file (or your `.bash_profile` if using bash), then save the file and close your existing terminal session
3. Confirm that `perlbrew` has been successfully initialized by running `perlbrew init` after launching a new terminal session
4. Set up your environment to use the latest version of Perl by running `perlbrew install perl-5.34.0`
5. Ensure that you use this from now on by running `perlbrew switch perl-5.34.0`
6. Execute `perlbrew install-cpanm` to enable the `cpanm` shortcut, which will simplify the Perl module installation process

Make sure you execute `perlbrew init` before attempting to run a Perl script in a fresh new terminal session.

#### Install Package

```
cpanm StandupGenerator
```

### Create Local Repository

If you have trouble downloading the package or just want to play around with the code yourself, you can clone down the repository. Ensure you already have Perl on your local computer. (You can check this by executing `perl -v`.)

1. Fork this repository
2. Clone it to your local computer
3. Execute any of the methods from this package from within your local version of the directory with a version of this command:

```
perl -Ilib -e 'require "./lib/StandupGenerator.pm"; StandupGenerator::create_standup("/Users/johndoe/projects/super-important-project/standups")'
```

Replace `create_standup` with whichever top-level method you want to use, and replace the inner string with the full file path to the directory in which you plan to store standups.

## Features

- Method to create a new standup file based off of information from yesterday's standup file
- Method to open a standup file based on parameters
- Method to open all standup files from the past week

## Usage

### Short Approach

After downloading the package, execute a version of the following command to automatically add the below shortcuts to your zsh or bash config file.

```
perl -e 'use StandupGenerator; set_aliases("/Users/johndoe/projects/super-important-project/standups")'
```

Replace the inner string with the exact path to the directory you plan to use to store your standups.

You can execute this command multiple times to reset the directory for your standups. For instance, after completing a project but before starting another, you would want to reset the directory to the directory for the new project. Each time you execute the command, three new functions will be added to the bottom of your zsh or bash config file. As a result, if you generate aliases on five different occassions, your zsh or bash config file will now have 15 different functions at the end of its file. Later commands always override earlier, identical commands, so this won't affect its ability to operate. However, feel free to delete older instances of the shortcuts as you see fit. Always make sure the directory you select will only contain standup files.

#### `csu`

This method **c**reates a new **s**tand**u**p. It is a shortcut for the `create_standup` method. It takes no arguments. It will create the file in the appropriate folder, then open it in your default text editor (e.g., TextEdit). If yesterday's standup was *s2d07.txt*, then to create and open *s2d08.txt*, merely run:

```
csu
```

#### `osu`

This method **o**pens an existing **s**tand**u**p. It is a shortcut for the `open_standup` method. It takes two arguments: a number for the sprint and two-digit string for the day. It will open the corresponding file from the already aliased folder in your default text editor (e.g., TextEdit). If you want to open *s1d03.txt*, then merely run:

```
osu 1 '03'
```

#### `wsu`

This method opens all of this past **w**eek's **s**tand**u**ps. It is a shortcut for the `view_standups_from_week` method. It takes no arguments. It will open six files from the already aliased folder in your default text editor (e.g., TextEdit). The files will be for the standups from Monday through Friday of the week in question, along with the following Monday's. It determines which files to open based on the last file in the directory, which it uses to determine the likely week. If it's Friday and you have already preemptively created this coming Monday's standup, which happens to be *s4d09.txt*, then you can open *s4d04.txt*, *s4d05.txt*, *s4d06.txt*, *s4d07.txt*, *s4d08.txt*, and *s4d09.txt* by merely running:

```
wsu
```

### Long Approach

If you don't want your config files edited and are fine with writing out long commands everytime, you can instead use the full commands.

Execute any of the methods from this package with a version of this command:

```
perl -e 'use StandupGenerator; create_standup("/Users/johndoe/projects/super-important-project/standups")'
```

Replace `create_standup` with whichever top-level method you want to use, and replace the inner string with the full file path to the directory in which you plan to store standups. Make sure you include all necessary parameters for the method you wish to use.

### Recommendation

Use the short approach. Let's say you have a new project called Project Ultra. You have a directory on you computer called `project-ultra` to house all materials related to this project. Here's how to use the Standup Generator.

1. Create a directory within `project-ultra` that will only hold the standup files; call it `standups` for simplicity
2. Install the package using the instructions above
3. Execute the initial Perl script indicated in the *Short Approach* section to generate the aliases (adjust the file path accordingly)
4. Create the first standup for this project by running `csu`
5. Fill in data about what you did yesterday, what you plan to do today, and what blockers you currently have in their respective sections
6. When you need to create the standup for tomorrow, merely run `csu` again; note that the content from yesterday's standup's *Today* section will be stored in the new standup's *Yesterday* and *Today* sections, and that yesterday's blockers will be mapped over to today's (under the assumption that this will probably be a time-saving hack)
7. If you ever need to view an earlier standup, use the `osu` shortcut; for instance, if on Thursday you want to view your standup from Tuesday, execute `osu 1 '02'`
8. At the end of the week, if you want to see all your standups for the past week, just run `wsu`; this is helpful if you need to fill in your activities on your timesheet for work

## Code Examples

**Helper function to find the last file in a directory**
```perl
sub find_last_file {
    my ($path) = @_;
    opendir my $dir, $path;
    my @files = readdir $dir;
    closedir $dir;
    my @sorted = sort @files;
    my $files_length = scalar(@files);
    my $last_file = $sorted[$files_length - 1];

    if (index($last_file, '.txt') == -1) {
        $last_file = 's0d0.txt';
    }

    return $last_file;
}
```

**Open a file via the system command based on specific parameters**
```perl
sub open_one {
    my ($path, $sprint, $day) = @_;
    my $command = "open ${path}/s${sprint}d${day}.txt";
    system($command);
}
```

## Testing

This repository uses the **Test::Simple** module for testing, which should come bundled with Perl by default. Tests are spread across 8 files within the `t` directory. To run all tests within a file, execute a version of this command:

```
perl -Ilib t/routines/create_new.t
```

Adjust file path appropriately.

## Future Goals

- Check config file for existence of shortcuts before inserting them when using the `save_script_shortcuts` method, and delete the existing ones before adding the new ones, to avoid adding redundant shortcuts to the user's config file
- Make Windows compatible, possibly with a separate version of this package
- Add fallback config file options to `save_script_shortcuts` method in case user uses neither zsh nor bash
- Allow user to enter days as numbers instead of two-digit strings in the `open_one` method
- Error handling for cases like attempting to open a file that doesn't exist, especially in the context of the `open_many` method, and for running `find_last_file` in a directory with non-standup files (either *.txt* or otherwise)
- More tests for edge cases, along with a way to test the `save_script_shortcuts` method