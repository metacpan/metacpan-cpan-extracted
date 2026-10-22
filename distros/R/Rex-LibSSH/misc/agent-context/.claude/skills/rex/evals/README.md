# Agent evaluation specification

[cases.json](cases.json) contains 20 scenario prompts with required and forbidden
behaviors. These are evaluation inputs, not an executed benchmark. The offline unit
tests verify the file's structure and unique identifiers, not an agent's responses.

To evaluate an agent, provide the skill through the actual host, ask each prompt in
an isolated session, and grade against the scenario criteria. Record the agent/model,
host configuration, loaded references, date, response, and reviewer decision. Do not
allow scenarios to connect to production or actually install packages. A correct
answer should distinguish documented behavior, source observations, and uncertainty.

Add integration cases for your controller/backend/target combinations separately;
a language-model answer cannot prove that a host-key check, file transfer, or GPU
workload works on actual infrastructure.
