"""Shared fixtures for mock-relay tests."""

from __future__ import annotations

import socket
import sys
from pathlib import Path
from typing import Iterator

import pytest


# Allow `import mock_relay` to resolve without an editable install. The
# package lives at ``../../test_harness/mock_relay/mock_relay/`` from this
# conftest. Walk this file's parents looking for a directory named
# ``test_harness`` containing the named package.
def _discover_mock_package(name: str) -> bool:
    here = Path(__file__).resolve()
    for parent in here.parents:
        candidate = parent / "test_harness" / name
        if (candidate / name / "__init__.py").is_file():
            entry = str(candidate)
            if entry not in sys.path:
                sys.path.insert(0, entry)
            return True
    return False


_discover_mock_package("mock_relay")

from mock_relay import MockRelayServer


def _free_port() -> int:
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind(("127.0.0.1", 0))
    port = s.getsockname()[1]
    s.close()
    return port


@pytest.fixture(scope="session")
def mock_relay_server() -> Iterator[MockRelayServer]:
    """Boot ONE mock relay server for the whole test session."""
    srv = MockRelayServer(
        host="127.0.0.1",
        ws_port=_free_port(),
        http_port=_free_port(),
        log_level="error",
    ).start()
    yield srv
    srv.stop()


@pytest.fixture(autouse=True)
def _reset_state(mock_relay_server: MockRelayServer):
    """Reset journal + scenarios + auth registry between tests."""
    mock_relay_server.state.journal.reset()
    mock_relay_server.state.scenarios.reset()
    mock_relay_server.state.auth.reset()
    yield
