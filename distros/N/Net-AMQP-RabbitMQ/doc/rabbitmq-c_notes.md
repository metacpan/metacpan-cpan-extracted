# Making Sense of `rabbitmq-c`

- A frame is a unit of transit across the network

- A message is conveyed using one or more frames



Q: How can I parse basic.ack?

A: Using `amqp_decode_method()`
