use mop;

role Local::MopRole {
	has $!attr is ro;
	method meth { 42 }
	method req;
}

1;
