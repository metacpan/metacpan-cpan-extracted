
JSON-Config (projekt.json)



 [
    {
        "label" : "Name",
        type : "text",    // 
        data: "name"      // mit diesen Werten wird es gefüllt, default: wie 'name'
        data_function: "" // alternative zu data -> führt Funktion aus
        selected: 123     // Vorauswahl (select und checkbox)
        name : "name"     // name
        id : "name"       // default: wie 'name'
        "rw" : [ "OTRS-Admin", "OTRS-User" ],
        "ro" : [ "Guest" ],
        "show" : 1                // zeige Feld im
        "validation" : [  // Mojolicious Validation rules
        ],
    },
 ]


Template:

<%= form_fields('projekt') %>

Controller:

 $self->stash( name => 123 );

Generated Output:

  <input type="text" name="name" value="123" id="name" />


Load the plugin

  $self->plugin( 'FormFieldsJSON' );


