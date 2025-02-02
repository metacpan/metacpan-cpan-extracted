# Developer Documentation

## Types

`Parser::FIT` defines various data types.

These types are all just definitions for hash refs.

No actuall types (aka classes) are used, since even small FIT files contain thousands of records which need to be parsed.
So that object construction overhead starts to matter.

### Field Descriptor

* `id` - The id of this field descriptor. IDs are only unique per global message!
* `name` - The name of this field
* `type` - The high level data type (e.G. `date_time`). Not to confuse with the low-level storage types (aka base types)
* `unit` - The unit of this value. May be `undef`.
* `scale` - The scale of this value. May be `undef`.
* `offset` - The offset of this value. May be `undef`.

### Global Message

* `name` - Global Message Name
* `fields` - List of FieldDescriptors

### Local Message

* `size` - Size of this message in bytes as it is encountered in the FIT file
* `dataFields` - Array of `Local Message Fields`
* `globaleMessage` - Reference to the `Global Message`
* `unpackTemplate` - The unpack template to parse the bytes inside the FIT file
* `isUnkownMessage` - Flag indicating unknown message (references an unknown global message)
* `isDeveloperMessage` - Flag indicating developer data

### Local Message Fields

* `baseType` - The baseType of this field. Meaning how it is stored in the FIT file
* `fieldDescriptor` - The field descriptor for this field

### Result Field

* `rawValue` - Raw value from the FIT file
* `value` - Post processed value
* `fieldDescriptor` - The field descriptor for this field

### Parse Result

* `messageType` - Message Type 
* `fields` - Hash of `Result Fields`