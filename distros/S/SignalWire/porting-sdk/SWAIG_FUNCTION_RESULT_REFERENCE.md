# SwaigFunctionResult Action Reference

This document defines the exact JSON output for every SwaigFunctionResult action method. Use this as the authoritative reference when implementing SwaigFunctionResult in any language.

## Serialization Format

```json
{
  "response": "Text the AI speaks back to the user",
  "action": [
    {"action_name": "action_value"},
    {"another_action": {"key": "value"}}
  ],
  "post_process": true
}
```

Rules:
- `response` — always included (string)
- `action` — only included if at least one action exists (array of objects)
- `post_process` — only included if `true` (boolean)

---

## Call Control Actions

### Connect(destination, final, from)
```json
{"SWML": {"sections": {"main": [{"connect": {"to": "<destination>", "from": "<from>"}}]}}}
```
- If `final` is true, also set `response` to the ai_response text
- If `from` is empty, omit the `"from"` field

### SwmlTransfer(dest, aiResponse, final)
```json
{"transfer_uri": "<dest>"}
```
- Sets `response` to `aiResponse`

### Hangup()
```json
{"hangup": {}}
```

### Hold(timeout)
```json
{"hold": {"timeout": <timeout>}}
```
- `timeout` should be clamped to 0-900

### WaitForUser(enabled, timeout, answerFirst)
```json
{"wait_for_user": {"enabled": true, "timeout": 30, "answer_first": false}}
```
- Omit fields that are nil/default
- If only `answerFirst` is true: `{"wait_for_user": {"answer_first": true}}`
- If no params at all: `{"wait_for_user": true}`

### Stop()
```json
{"stop": true}
```

---

## State & Data Management

### UpdateGlobalData(data)
```json
{"set_global_data": {"key1": "value1", "key2": "value2"}}
```

### RemoveGlobalData(keys)
```json
{"remove_global_data": {"keys": ["key1", "key2"]}}
```

### SetMetadata(data)
```json
{"set_meta_data": {"key1": "value1"}}
```

### RemoveMetadata(keys)
```json
{"remove_meta_data": {"keys": ["key1", "key2"]}}
```

### SwmlUserEvent(eventData)
```json
{"user_event": {"event_name": "my_event", "data": "anything"}}
```

### SwmlChangeStep(stepName)
```json
{"context_switch": {"step": "<stepName>"}}
```

### SwmlChangeContext(contextName)
```json
{"context_switch": {"context": "<contextName>"}}
```

### SwitchContext(systemPrompt, userPrompt, consolidate, fullReset, isolated)
Simple form (just systemPrompt):
```json
{"context_switch": {"system_prompt": "<text>"}}
```

Full form (only include non-empty/non-false fields):
```json
{"context_switch": {
  "system_prompt": "<text>",
  "user_prompt": "<text>",
  "consolidate": true,
  "full_reset": true,
  "isolated": true
}}
```

### ReplaceInHistory(text)
If `text` is a string:
```json
{"replace_history": "<text>"}
```
If `text` is boolean `true`:
```json
{"replace_history": "summary"}
```

---

## Media Control

### Say(text)
```json
{"say": "<text>"}
```

### PlayBackgroundFile(filename, wait=false)
Without wait:
```json
{"play_background_file": "<filename>"}
```
With wait:
```json
{"play_background_file_wait": "<filename>"}
```

### StopBackgroundFile()
```json
{"stop_background_file": true}
```

### RecordCall(controlID, stereo, format, direction)
```json
{"record_call": {
  "control_id": "<controlID>",
  "stereo": true,
  "format": "wav",
  "direction": "both",
  "initiator": "system"
}}
```
- Omit `control_id` if empty
- Defaults: stereo=false, format="wav", direction="both"

### StopRecordCall(controlID)
```json
{"stop_record_call": {"control_id": "<controlID>"}}
```
- Omit `control_id` if empty: `{"stop_record_call": {}}`

---

## Speech & AI Configuration

### AddDynamicHints(hints)
```json
{"add_dynamic_hints": ["hint1", "hint2", {"pattern": "regex"}]}
```

### ClearDynamicHints()
```json
{"clear_dynamic_hints": true}
```

### SetEndOfSpeechTimeout(milliseconds)
```json
{"end_of_speech_timeout": 500}
```

### SetSpeechEventTimeout(milliseconds)
```json
{"speech_event_timeout": 3000}
```

### ToggleFunctions(toggles)
```json
{"toggle_functions": [
  {"function": "func1", "active": true},
  {"function": "func2", "active": false}
]}
```

### EnableFunctionsOnTimeout(enabled)
```json
{"functions_on_timeout": true}
```

### EnableExtensiveData(enabled)
```json
{"extensive_data": true}
```

### UpdateSettings(settings)
```json
{"ai_settings": {"temperature": 0.5, "top_p": 0.9}}
```

---

## Advanced Features

### ExecuteSwml(swmlContent, transfer=false)
Without transfer:
```json
{"SWML": {"version": "1.0.0", "sections": {"main": [...]}}}
```
With transfer:
```json
{"transfer_swml": {"version": "1.0.0", "sections": {"main": [...]}}}
```
- `swmlContent` can be a map/dict or a JSON string

### JoinConference(name, muted, beep, holdAudio)
```json
{"join_conference": {
  "name": "<name>",
  "muted": false,
  "beep": "true",
  "hold_audio": "ring"
}}
```

### JoinRoom(name)
```json
{"join_room": {"name": "<name>"}}
```

### SipRefer(toURI)
```json
{"sip_refer": {"to_uri": "<toURI>"}}
```

### Tap(uri, controlID, direction, codec)
```json
{"tap": {
  "uri": "<uri>",
  "control_id": "<controlID>",
  "direction": "both",
  "codec": "PCMU"
}}
```
- Omit `control_id` if empty, `direction` defaults to "both", `codec` if empty

### StopTap(controlID)
```json
{"stop_tap": {"control_id": "<controlID>"}}
```
- Omit `control_id` if empty: `{"stop_tap": {}}`

### SendSms(toNumber, fromNumber, body, media, tags)
```json
{"send_sms": {
  "to_number": "+15551234567",
  "from_number": "+15559876543",
  "body": "Hello!",
  "media": ["https://example.com/image.jpg"],
  "tags": ["vip"]
}}
```
- Omit `media` and `tags` if nil/empty

### Pay(connectorURL, inputMethod, actionURL, timeout, maxAttempts)
```json
{"pay": {
  "payment_connector_url": "<url>",
  "input_method": "dtmf",
  "action_url": "action_url",
  "timeout": 600,
  "max_attempts": 3
}}
```

---

## RPC Actions

### ExecuteRpc(method, params)
```json
{"execute_rpc": {
  "method": "<method>",
  "params": {"key": "value"},
  "jsonrpc": "2.0"
}}
```
- Omit `params` if nil/empty

### RpcDial(toNumber, fromNumber, destSwml, callTimeout, region)
Delegates to ExecuteRpc with:
```json
{"execute_rpc": {
  "method": "calling.dial",
  "params": {
    "to_number": "+15551234567",
    "from_number": "+15559876543",
    "dest_swml": "<swml_url>",
    "call_timeout": 30,
    "region": "us"
  },
  "jsonrpc": "2.0"
}}
```
- Omit `call_timeout` if nil, `region` if empty

### RpcAiMessage(callID, messageText)
```json
{"execute_rpc": {
  "method": "calling.ai_message",
  "params": {"call_id": "<callID>", "message_text": "<text>"},
  "jsonrpc": "2.0"
}}
```

### RpcAiUnhold(callID)
```json
{"execute_rpc": {
  "method": "calling.ai_unhold",
  "params": {"call_id": "<callID>"},
  "jsonrpc": "2.0"
}}
```

### SimulateUserInput(text)
```json
{"simulate_user_input": "<text>"}
```
