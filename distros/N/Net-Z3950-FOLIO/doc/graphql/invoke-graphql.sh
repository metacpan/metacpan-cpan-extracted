#!/bin/sh

# Demonstration of invoking GraphQL directly

. ~/.okapi
curl \
	-i \
	-X POST \
	-H "Content-Type: application/json" \
	-H "X-Okapi-Url: ${OKAPI_URL}" \
	-H "X-Okapi-Tenant: ${OKAPI_TENANT}" \
	-H "X-Okapi-Token: ${OKAPI_TOKEN}" \
	-d '{ "query": "query { instance_storage_instances { instances { title contributors { name } } } }" }' \
	http://localhost:3001/graphql
