import { Link, router } from '@inertiajs/react'

type Todo = {
  id: number
  title: string
  completed: number
}

type Props = {
  recent_todos?: Todo[]
  loadingSection: string | null
  setLoadingSection: (section: string | null) => void
}

export default function RecentTodosSection({ recent_todos, loadingSection, setLoadingSection }: Props) {
  const refreshRecentTodos = () => {
    setLoadingSection('recent_todos')
    router.reload({
      only: ['recent_todos'],
      onFinish: () => setLoadingSection(null),
    })
  }

  return (
    <div className="mb-8">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-xl font-semibold text-gray-800">
          Recent Todos
          {loadingSection === 'recent_todos' && <span className="text-sm text-gray-500 ml-2">(Updating...)</span>}
        </h2>
        <button
          onClick={refreshRecentTodos}
          disabled={loadingSection !== null}
          className="px-3 py-1 bg-gray-500 text-white rounded hover:bg-gray-600 disabled:opacity-50 transition-colors"
        >
          Refresh Todos Only
        </button>
      </div>
      {recent_todos ? (
        <div className="bg-white rounded-lg border border-gray-200">
          {recent_todos.length > 0 ? (
            <ul className="divide-y divide-gray-200">
              {recent_todos.map(todo => (
                <li key={todo.id} className="p-4 hover:bg-gray-50">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <span className={todo.completed ? 'text-green-600' : 'text-gray-400'}>
                        {todo.completed ? '✓' : '○'}
                      </span>
                      <span className={todo.completed ? 'line-through text-gray-500' : 'text-gray-800'}>
                        {todo.title}
                      </span>
                    </div>
                    <Link
                      href={`/todos/${todo.id}`}
                      className="text-sm text-blue-600 hover:text-blue-800"
                    >
                      View
                    </Link>
                  </div>
                </li>
              ))}
            </ul>
          ) : (
            <p className="p-4 text-gray-500 text-center">No todos yet</p>
          )}
        </div>
      ) : (
        <div className="bg-gray-100 p-8 rounded-lg text-center text-gray-500">
          Recent todos not loaded
        </div>
      )}
    </div>
  )
}
