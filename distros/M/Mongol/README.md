# mongol

## Build status

[![Build Status](https://travis-ci.org/marghidanu/mongol.svg?branch=master)](https://travis-ci.org/marghidanu/mongol)

## Description

Moose-based MongoDB ODM for Perl.

## Development environment

It's quite easy to setup the development environment, just follow the steps below. It does require **VirtualBox** an **Vagrant** to be installed on your machine.

	vagrant up
	vagrant ssh

	sudo su -
	cd /vagrant

	perl Build.PL
	./Build installdeps
	./Build
	./Build test

**NOTE**

Ever since I started using the **Xenial** image vagrant generated a log file in the project directory. You can easily remove the file otherwise it will be included in the distribution.

## Installation

### Directly from GitHub

You gotta love **cpanm** ever since a few releases ago it allows package installation straight from GitHub:

	curl -sL http://cpanmin.us | perl - App::cpanminus
	cpanm https://github.com/marghidanu/mongol.git

### Manual installation

	git clone https://github.com/marghidanu/mongol.git
	cd mongol

	perl Build.PL
	./Build installdeps
	./Build
	./Build test
	./Build install
