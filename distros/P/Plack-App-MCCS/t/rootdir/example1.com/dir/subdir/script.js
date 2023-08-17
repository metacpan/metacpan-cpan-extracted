$(document).ready(function() {
	var name = $('#name').val();
	var password = $('#password').val();

	showSomething(name, password);
});

function showSomething(name, password) {
	alert("Hi "+name+", your password is "+password+" and I am going to broadcast it to the entire world.");
}
