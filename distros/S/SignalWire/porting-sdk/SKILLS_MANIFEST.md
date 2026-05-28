# SignalWire AI Agents SDK — Built-in Skills Manifest

Exact specifications for all 17 built-in skills. Use this as the authoritative reference when porting skills to a new language.

## Summary

| # | Skill Name | Tool Name(s) | Multi-Instance | DataMap | Env Vars |
|---|-----------|---------------|----------------|---------|----------|
| 1 | api_ninjas_trivia | get_trivia | Yes | Yes | — |
| 2 | claude_skills | claude_{name} (dynamic) | Yes | No | — |
| 3 | datasphere | search_knowledge | Yes | No | — |
| 4 | datasphere_serverless | search_knowledge | Yes | Yes | — |
| 5 | datetime | get_current_time, get_current_date | No | No | — |
| 6 | google_maps | lookup_address, compute_route | No | No | — |
| 7 | info_gatherer | start_questions, submit_answer | Yes | No | — |
| 8 | joke | get_joke | No | Yes | — |
| 9 | math | calculate | No | No | — |
| 10 | mcp_gateway | mcp_{service}_{tool} (dynamic) | No | No | — |
| 11 | native_vector_search | search_knowledge | Yes | No | — |
| 12 | play_background_file | play_background_file | Yes | Yes | — |
| 13 | spider | scrape_url, crawl_site, extract_structured_data | Yes | No | — |
| 14 | swml_transfer | transfer_call | Yes | Yes | — |
| 15 | weather_api | get_weather | No | Yes | — |
| 16 | web_search | web_search | Yes | No | — |
| 17 | wikipedia_search | search_wiki | No | No | — |

**Note:** No skills have hard-coded REQUIRED_ENV_VARS. All API keys are passed via params with optional env var fallback configured in the parameter schema.

---

## 1. api_ninjas_trivia

- **SKILL_NAME:** `"api_ninjas_trivia"`
- **SKILL_DESCRIPTION:** `"Get trivia questions from API Ninjas"`
- **SUPPORTS_MULTIPLE_INSTANCES:** `true`
- **Tool:** `get_trivia` (configurable via `tool_name` param)
- **Tool Description:** `"Get trivia questions for {tool_name}"`
- **Tool Parameters:** `category` (string, required, enum of category keys)
- **Implementation:** DataMap with GET to `https://api.api-ninjas.com/v1/trivia?category=%{args.category}`, X-Api-Key header
- **Output template:** `"Category %{array[0].category} question: %{array[0].question} Answer: %{array[0].answer}, be sure to give the user time to answer before saying the answer."`
- **Parameter Schema:** `api_key` (required, hidden), `categories` (array, default: all), `tool_name`
- **Prompt Sections:** None
- **Hints:** None
- **Global Data:** None

---

## 2. claude_skills

- **SKILL_NAME:** `"claude_skills"`
- **SKILL_DESCRIPTION:** `"Load Claude SKILL.md files as agent tools"`
- **SUPPORTS_MULTIPLE_INSTANCES:** `true`
- **REQUIRED_PACKAGES:** `["yaml"]`
- **Tool:** Dynamic — one tool per discovered .md skill file, naming: `{tool_prefix}{sanitized_name}` (prefix default: `"claude_"`)
- **Tool Parameters:** `arguments` (string, required), optional `section` (string, enum from .md files)
- **Implementation:** Custom handler — reads SKILL.md files with YAML frontmatter, creates tools from them
- **Parameter Schema:** `skills_path` (required), `include`/`exclude` (glob patterns), `skill_descriptions`, `tool_prefix`, `response_prefix`/`response_postfix`, `allow_shell_injection`, `allow_script_execution`, `shell_timeout`
- **Prompt Sections:** One section per discovered skill with body and section references
- **Hints:** Words from skill names (split on `-` and `_`)
- **Global Data:** None

---

## 3. datasphere

- **SKILL_NAME:** `"datasphere"`
- **SKILL_DESCRIPTION:** `"Search knowledge using SignalWire DataSphere RAG stack"`
- **SUPPORTS_MULTIPLE_INSTANCES:** `true`
- **REQUIRED_PACKAGES:** `["requests"]`
- **Tool:** `search_knowledge` (configurable)
- **Tool Description:** `"Search the knowledge base for information on any topic and return relevant results"`
- **Tool Parameters:** `query` (string, required)
- **Implementation:** Custom HTTP handler — POST to `https://{space}/api/datasphere/documents/search`
- **Parameter Schema:** `space_name`, `project_id`, `token`, `document_id` (all required), `count` (int, default 1, min 1, max 10), `distance` (float, default 3.0), `tags` (array), `language`, `pos_to_expand`, `max_synonyms`, `no_results_message`
- **Prompt Sections:** "Knowledge Search Capability" with body and bullets
- **Hints:** `[]`
- **Global Data:** `{"datasphere_enabled": true, "document_id": "...", "knowledge_provider": "SignalWire DataSphere"}`

---

## 4. datasphere_serverless

- **SKILL_NAME:** `"datasphere_serverless"`
- **SKILL_DESCRIPTION:** `"Search knowledge using SignalWire DataSphere with serverless DataMap execution"`
- **SUPPORTS_MULTIPLE_INSTANCES:** `true`
- **Tool:** `search_knowledge` (configurable)
- **Tool Description:** `"Search the knowledge base for information on any topic and return relevant results"`
- **Tool Parameters:** `query` (string, required)
- **Implementation:** DataMap with POST webhook to DataSphere API, Basic Auth, `foreach` loop over chunks
- **Output template:** `'I found results for "${args.query}":\n\n${formatted_results}'`
- **Parameter Schema:** Same as datasphere
- **Prompt Sections:** "Knowledge Search Capability (Serverless)" with body and bullets
- **Hints:** `[]`
- **Global Data:** `{"datasphere_serverless_enabled": true, "document_id": "...", "knowledge_provider": "SignalWire DataSphere (Serverless)"}`

---

## 5. datetime

- **SKILL_NAME:** `"datetime"`
- **SKILL_DESCRIPTION:** `"Get current date, time, and timezone information"`
- **SUPPORTS_MULTIPLE_INSTANCES:** `false`
- **REQUIRED_PACKAGES:** `["pytz"]` (use language equivalent)
- **Tools:**
  - `get_current_time` — `"Get the current time, optionally in a specific timezone"` — params: `timezone` (string, optional, default UTC)
  - `get_current_date` — `"Get the current date"` — params: `timezone` (string, optional, default UTC)
- **Implementation:** Custom handler — uses timezone library
- **Parameter Schema:** Base schema only
- **Prompt Sections:** "Date and Time Information" with body and bullets
- **Hints:** `[]`
- **Global Data:** None

---

## 6. google_maps

- **SKILL_NAME:** `"google_maps"`
- **SKILL_DESCRIPTION:** `"Validate addresses and compute driving routes using Google Maps"`
- **REQUIRED_PACKAGES:** `["requests"]`
- **Tools:**
  - `lookup_address` (configurable) — params: `address` (string), `bias_lat`/`bias_lng` (number, optional)
  - `compute_route` (configurable) — params: `origin_lat`, `origin_lng`, `dest_lat`, `dest_lng` (all numbers)
- **Implementation:** Custom handler with Google Maps APIs (Geocoding + Routes)
- **Parameter Schema:** `api_key` (required, hidden), `lookup_tool_name`, `route_tool_name`
- **Prompt Sections:** "Google Maps" with bullets for both tools
- **Hints:** `["address", "location", "route", "directions", "miles", "distance"]`
- **Global Data:** None

---

## 7. info_gatherer

- **SKILL_NAME:** `"info_gatherer"`
- **SKILL_DESCRIPTION:** `"Gather answers to a configurable list of questions"`
- **SUPPORTS_MULTIPLE_INSTANCES:** `true`
- **Tools:**
  - `start_questions` (prefixed) — no params, returns first question
  - `submit_answer` (prefixed) — params: `answer` (string, required), `confirmed_by_user` (boolean)
- **Implementation:** Stateful handler using global data for question index and answers
- **Parameter Schema:** `questions` (array of {key_name, question_text, confirm, prompt_add}), `prefix`, `completion_message`
- **Prompt Sections:** "Info Gatherer ({instance_key})" with instructions
- **Hints:** None
- **Global Data:** `{namespace: {"questions": [...], "question_index": 0, "answers": []}}`

---

## 8. joke

- **SKILL_NAME:** `"joke"`
- **SKILL_DESCRIPTION:** `"Tell jokes using the API Ninjas joke API"`
- **Tool:** `get_joke` (configurable via `tool_name`)
- **Tool Description:** `"Get a random joke from API Ninjas"`
- **Tool Parameters:** `type` (string, required, enum: `["jokes", "dadjokes"]`)
- **Implementation:** DataMap with GET to `https://api.api-ninjas.com/v1/${args.type}`, X-Api-Key header
- **Output template:** `"Here's a joke: ${array[0].joke}"`
- **Fallback:** Built-in joke if API fails
- **Parameter Schema:** `api_key` (required, hidden), `tool_name` (default: `"get_joke"`)
- **Prompt Sections:** "Joke Telling" with body and bullets
- **Hints:** `[]`
- **Global Data:** `{"joke_skill_enabled": true}`

---

## 9. math

- **SKILL_NAME:** `"math"`
- **SKILL_DESCRIPTION:** `"Perform basic mathematical calculations"`
- **Tool:** `calculate`
- **Tool Description:** `"Perform a mathematical calculation with basic operations (+, -, *, /, %, **)"`
- **Tool Parameters:** `expression` (string, required)
- **Implementation:** Safe AST-based expression evaluator (no eval/exec)
- **Parameter Schema:** Base schema only
- **Prompt Sections:** "Mathematical Calculations" with bullets
- **Hints:** `[]`
- **Global Data:** None

---

## 10. mcp_gateway

- **SKILL_NAME:** `"mcp_gateway"`
- **SKILL_DESCRIPTION:** `"Bridge MCP servers with SWAIG functions"`
- **Tool:** Dynamic — `{tool_prefix}{service_name}_{tool_name}` (prefix default: `"mcp_"`)
- **Tool Description:** `"[{service_name}] {tool description}"`
- **Implementation:** Custom HTTP handler — communicates with MCP gateway service
- **Parameter Schema:** `gateway_url` (required), `auth_token` (hidden), `auth_user`/`auth_password`, `services` (array), `session_timeout`, `tool_prefix`, `retry_attempts`, `request_timeout`, `verify_ssl`
- **Prompt Sections:** "MCP Gateway Integration" with connected services
- **Hints:** `["MCP", "gateway", ...service_names]`
- **Global Data:** `{"mcp_gateway_url": url, "mcp_session_id": null, "mcp_services": [...]}`

---

## 11. native_vector_search

- **SKILL_NAME:** `"native_vector_search"`
- **SKILL_DESCRIPTION:** `"Search document indexes using vector similarity and keyword search (local or remote)"`
- **SUPPORTS_MULTIPLE_INSTANCES:** `true`
- **Tool:** `search_knowledge` (configurable)
- **Tool Description:** Configurable (default: `"Search the local knowledge base for information"`)
- **Tool Parameters:** `query` (string, required), `count` (integer, configurable default)
- **Implementation:** SearchEngine API (local .swsearch files or remote HTTP endpoint)
- **For porting:** Network/remote mode only — skip local vector search
- **Parameter Schema:** `index_file`, `remote_url`, `index_name`, `count`, `similarity_threshold`, `tags`, `description`, `hints`, `model_name`, `backend`, `connection_string`, `collection_name`, etc.
- **Hints:** `["search", "find", "look up", "documentation", "knowledge base", ...custom]`
- **Global Data:** Search stats if available

---

## 12. play_background_file

- **SKILL_NAME:** `"play_background_file"`
- **SKILL_DESCRIPTION:** `"Control background file playback"`
- **SUPPORTS_MULTIPLE_INSTANCES:** `true`
- **Tool:** `play_background_file` (configurable)
- **Tool Description:** `"Control background file playback for {tool_name}"`
- **Tool Parameters:** `action` (string, required, enum: `["start_{key}", ..., "stop"]`)
- **Implementation:** DataMap with expressions for pattern matching, uses `play_background_file()` / `stop_background_file()` actions
- **Parameter Schema:** `files` (array, required) — objects: `key`, `description`, `url` (all required), `wait` (optional bool)
- **Prompt Sections:** None
- **Hints:** None
- **Global Data:** None

---

## 13. spider

- **SKILL_NAME:** `"spider"`
- **SKILL_DESCRIPTION:** `"Fast web scraping and crawling capabilities"`
- **SUPPORTS_MULTIPLE_INSTANCES:** `true`
- **REQUIRED_PACKAGES:** `["lxml"]`
- **Tools:**
  - `scrape_url` (prefixed) — params: `url` (required)
  - `crawl_site` (prefixed) — params: `start_url` (required)
  - `extract_structured_data` (prefixed) — params: `url` (required)
- **Implementation:** HTTP fetch + HTML parsing with lxml/BeautifulSoup
- **Parameter Schema:** `delay`, `concurrent_requests`, `timeout`, `max_pages`, `max_depth`, `extract_type` (enum: fast_text/clean_text/full_text/html/custom), `max_text_length`, `selectors`, `follow_patterns`, `user_agent`, `headers`, `follow_robots_txt`, `cache_enabled`
- **Hints:** `["scrape", "crawl", "extract", "web page", "website", "spider"]`
- **Global Data:** None

---

## 14. swml_transfer

- **SKILL_NAME:** `"swml_transfer"`
- **SKILL_DESCRIPTION:** `"Transfer calls between agents based on pattern matching"`
- **SUPPORTS_MULTIPLE_INSTANCES:** `true`
- **Tool:** `transfer_call` (configurable)
- **Tool Description:** Configurable (default: `"Transfer call based on pattern matching"`)
- **Tool Parameters:** `transfer_type` (string, required, configurable name) + optional `required_fields`
- **Implementation:** DataMap with regex expressions for pattern matching, calls `swml_transfer()` or `connect()` actions
- **Parameter Schema:** `transfers` (object, required) — pattern keys → config: `url`/`address`, `message`, `return_message`, `post_process`, `final`, `from_addr`; plus `description`, `parameter_name`, `parameter_description`, `default_message`, `required_fields`
- **Prompt Sections:** "Transferring" (destination list) + "Transfer Instructions"
- **Hints:** Words from transfer patterns + `["transfer", "connect", "speak to", "talk to"]`
- **Global Data:** None

---

## 15. weather_api

- **SKILL_NAME:** `"weather_api"`
- **SKILL_DESCRIPTION:** `"Get current weather information from WeatherAPI.com"`
- **Tool:** `get_weather` (configurable via `tool_name`)
- **Tool Description:** `"Get current weather information for any location"`
- **Tool Parameters:** `location` (string, required)
- **Implementation:** DataMap with GET to `https://api.weatherapi.com/v1/current.json?key={api_key}&q=${lc:enc:args.location}&aqi=no`
- **Output template:** Temperature, feels like, condition, humidity, wind (varies by `temperature_unit` setting)
- **Parameter Schema:** `api_key` (required, hidden), `tool_name` (default: `"get_weather"`), `temperature_unit` (enum: fahrenheit/celsius, default: fahrenheit)
- **Prompt Sections:** None
- **Hints:** None
- **Global Data:** None

---

## 16. web_search

- **SKILL_NAME:** `"web_search"`
- **SKILL_DESCRIPTION:** `"Search the web for information using Google Custom Search API"`
- **SKILL_VERSION:** `"2.0.0"`
- **SUPPORTS_MULTIPLE_INSTANCES:** `true`
- **REQUIRED_PACKAGES:** `["bs4", "requests"]`
- **Tool:** `web_search` (configurable)
- **Tool Description:** `"Search the web for high-quality information, automatically filtering low-quality results"`
- **Tool Parameters:** `query` (string, required)
- **Implementation:** Custom handler — Google Custom Search API + quality scoring/filtering
- **Parameter Schema:** `api_key`, `search_engine_id` (both required, hidden), `num_results` (int, default 3, min 1, max 10), `delay`, `max_content_length`, `oversample_factor`, `min_quality_score`, `no_results_message`
- **Prompt Sections:** "Web Search Capability (Quality Enhanced)" with bullets
- **Hints:** `[]`
- **Global Data:** `{"web_search_enabled": true, "search_provider": "Google Custom Search", "quality_filtering": true}`

---

## 17. wikipedia_search

- **SKILL_NAME:** `"wikipedia_search"`
- **SKILL_DESCRIPTION:** `"Search Wikipedia for information about a topic and get article summaries"`
- **REQUIRED_PACKAGES:** `["requests"]`
- **Tool:** `search_wiki`
- **Tool Description:** `"Search Wikipedia for information about a topic and get article summaries"`
- **Tool Parameters:** `query` (string, required)
- **Implementation:** Custom handler — Wikipedia REST API (search + extract)
- **Parameter Schema:** `num_results` (int, default 1, min 1, max 5), `no_results_message`
- **Prompt Sections:** "Wikipedia Search" with body and bullets
- **Hints:** `[]`
- **Global Data:** None

---

## Common Parameter Schema (inherited by all skills)

All skills inherit these base parameters from SkillBase:

```json
{
  "swaig_fields": {
    "type": "object",
    "description": "Additional SWAIG fields to merge into tool definitions (e.g., fillers, meta_data_token)"
  },
  "skip_prompt": {
    "type": "boolean",
    "description": "If true, skip injecting prompt sections",
    "default": false
  },
  "tool_name": {
    "type": "string",
    "description": "Override the default tool name (for multi-instance skills)"
  }
}
```
